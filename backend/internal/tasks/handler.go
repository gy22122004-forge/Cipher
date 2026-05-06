package tasks

import (
	"net/http"
	"strings"

	"github.com/ethara/backend/internal/models"
	"github.com/ethara/backend/pkg/response"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type Handler struct{ db *gorm.DB }

func NewHandler(db *gorm.DB) *Handler { return &Handler{db: db} }

type taskReq struct {
	Title       string  `json:"title"`
	Description string  `json:"description"`
	Status      string  `json:"status"`
	Priority    string  `json:"priority"`
	AssigneeID  *string `json:"assignee_id"`
}

func (r *taskReq) validate() (string, string) {
	r.Title = strings.TrimSpace(r.Title)
	if len(r.Title) < 2 {
		return "title", "task title must be at least 2 characters"
	}
	if len(r.Title) > 200 {
		return "title", "task title must be at most 200 characters"
	}
	if r.Status != "" {
		valid := map[string]bool{"todo": true, "in_progress": true, "done": true}
		if !valid[r.Status] {
			return "status", "status must be one of: todo, in_progress, done"
		}
	}
	if r.Priority != "" {
		valid := map[string]bool{"low": true, "medium": true, "high": true}
		if !valid[r.Priority] {
			return "priority", "priority must be one of: low, medium, high"
		}
	}
	return "", ""
}

// GetByProject — GET /api/v1/projects/:id/tasks  [auth]
// Supports ?status= and ?priority= filters.
func (h *Handler) GetByProject(c *gin.Context) {
	// Verify project exists
	var project models.Project
	if err := h.db.First(&project, "id = ?", c.Param("id")).Error; err != nil {
		response.Err(c, http.StatusNotFound, "project not found")
		return
	}

	q := h.db.Preload("Assignee").Where("project_id = ?", c.Param("id"))
	if status := c.Query("status"); status != "" {
		q = q.Where("status = ?", status)
	}
	if priority := c.Query("priority"); priority != "" {
		q = q.Where("priority = ?", priority)
	}

	var tasks []models.Task
	q.Order("created_at DESC").Find(&tasks)
	response.OK(c, "tasks fetched", tasks)
}

// Create — POST /api/v1/projects/:id/tasks  [admin, manager]
func (h *Handler) Create(c *gin.Context) {
	// Verify project exists
	var project models.Project
	if err := h.db.First(&project, "id = ?", c.Param("id")).Error; err != nil {
		response.Err(c, http.StatusNotFound, "project not found")
		return
	}

	// Business rule: cannot add tasks to a completed project
	if project.Status == models.ProjectCompleted {
		response.Err(c, http.StatusConflict, "cannot add tasks to a completed project")
		return
	}

	var req taskReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Err(c, http.StatusBadRequest, "invalid request body")
		return
	}
	if field, msg := req.validate(); msg != "" {
		response.FieldErr(c, field, msg)
		return
	}

	// Validate assignee exists if provided
	if req.AssigneeID != nil && *req.AssigneeID != "" {
		var assignee models.User
		if err := h.db.First(&assignee, "id = ?", *req.AssigneeID).Error; err != nil {
			response.FieldErr(c, "assignee_id", "assigned user does not exist")
			return
		}
	}

	t := models.Task{
		Title:       req.Title,
		Description: strings.TrimSpace(req.Description),
		Status:      models.TaskTodo,
		Priority:    models.PriorityMedium,
		ProjectID:   c.Param("id"),
		AssigneeID:  req.AssigneeID,
	}
	if req.Status != "" {
		t.Status = models.TaskStatus(req.Status)
	}
	if req.Priority != "" {
		t.Priority = models.TaskPriority(req.Priority)
	}

	if err := h.db.Create(&t).Error; err != nil {
		response.Err(c, http.StatusInternalServerError, "failed to create task")
		return
	}
	h.db.Preload("Assignee").First(&t, "id = ?", t.ID)
	response.Created(c, "task created", t)
}

// GetByID — GET /api/v1/tasks/:id  [auth]
func (h *Handler) GetByID(c *gin.Context) {
	var t models.Task
	if err := h.db.Preload("Assignee").Preload("Project.Owner").First(&t, "id = ?", c.Param("id")).Error; err != nil {
		response.Err(c, http.StatusNotFound, "task not found")
		return
	}
	response.OK(c, "task fetched", t)
}

// Update — PUT /api/v1/tasks/:id  [auth — members can only update their assigned tasks]
func (h *Handler) Update(c *gin.Context) {
	var t models.Task
	if err := h.db.First(&t, "id = ?", c.Param("id")).Error; err != nil {
		response.Err(c, http.StatusNotFound, "task not found")
		return
	}

	// Business rule: members can only update tasks assigned to them
	userRole := c.GetString("user_role")
	userID   := c.GetString("user_id")
	if userRole == "member" {
		if t.AssigneeID == nil || *t.AssigneeID != userID {
			response.Err(c, http.StatusForbidden, "you can only update tasks assigned to you")
			return
		}
	}

	var req taskReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Err(c, http.StatusBadRequest, "invalid request body")
		return
	}
	if field, msg := req.validate(); msg != "" {
		response.FieldErr(c, field, msg)
		return
	}

	// Business rule: validate status transition
	if req.Status != "" && !validTransition(string(t.Status), req.Status) {
		response.Err(c, http.StatusConflict,
			"invalid status transition: "+string(t.Status)+" → "+req.Status)
		return
	}

	t.Title       = req.Title
	t.Description = strings.TrimSpace(req.Description)
	t.AssigneeID  = req.AssigneeID
	if req.Status != "" {
		t.Status = models.TaskStatus(req.Status)
	}
	if req.Priority != "" {
		t.Priority = models.TaskPriority(req.Priority)
	}

	if err := h.db.Save(&t).Error; err != nil {
		response.Err(c, http.StatusInternalServerError, "failed to update task")
		return
	}
	h.db.Preload("Assignee").First(&t, "id = ?", t.ID)
	response.OK(c, "task updated", t)
}

// Delete — DELETE /api/v1/tasks/:id  [admin, manager]
func (h *Handler) Delete(c *gin.Context) {
	var t models.Task
	if err := h.db.First(&t, "id = ?", c.Param("id")).Error; err != nil {
		response.Err(c, http.StatusNotFound, "task not found")
		return
	}

	// Business rule: managers can only delete tasks in their own projects
	if c.GetString("user_role") == "manager" {
		var p models.Project
		h.db.First(&p, "id = ?", t.ProjectID)
		if p.OwnerID != c.GetString("user_id") {
			response.Err(c, http.StatusForbidden, "managers can only delete tasks in their own projects")
			return
		}
	}

	if err := h.db.Delete(&t).Error; err != nil {
		response.Err(c, http.StatusInternalServerError, "failed to delete task")
		return
	}
	response.NoContent(c)
}

// validTransition enforces a simple workflow: todo → in_progress → done (or any reverse).
// Admins and managers bypass this check upstream; it only applies to business-logic validation.
func validTransition(from, to string) bool {
	// Allow any transition for simplicity; you can tighten here
	allowed := map[string][]string{
		"todo":        {"in_progress", "done"},
		"in_progress": {"todo", "done"},
		"done":        {"todo", "in_progress"},
	}
	for _, t := range allowed[from] {
		if t == to {
			return true
		}
	}
	return false
}
