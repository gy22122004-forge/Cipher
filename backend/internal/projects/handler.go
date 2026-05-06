package projects

import (
	"net/http"
	"strings"
	"time"

	"github.com/ethara/backend/internal/models"
	"github.com/ethara/backend/pkg/response"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type Handler struct{ db *gorm.DB }

func NewHandler(db *gorm.DB) *Handler { return &Handler{db: db} }

type projectReq struct {
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Status      string  `json:"status"`
	Deadline    *string `json:"deadline"` // "YYYY-MM-DD"
}

func (r *projectReq) validate() (string, string) {
	r.Name = strings.TrimSpace(r.Name)
	if len(r.Name) < 2 {
		return "name", "project name must be at least 2 characters"
	}
	if len(r.Name) > 100 {
		return "name", "project name must be at most 100 characters"
	}
	if r.Status != "" {
		valid := map[string]bool{"active": true, "completed": true, "on_hold": true}
		if !valid[r.Status] {
			return "status", "status must be one of: active, completed, on_hold"
		}
	}
	if r.Deadline != nil {
		if _, err := time.Parse("2006-01-02", *r.Deadline); err != nil {
			return "deadline", "deadline must be in YYYY-MM-DD format"
		}
	}
	return "", ""
}

// GetAll — GET /api/v1/projects  [auth]
// Supports ?status= and ?search= query params.
func (h *Handler) GetAll(c *gin.Context) {
	q := h.db.Preload("Owner")

	if status := c.Query("status"); status != "" {
		q = q.Where("status = ?", status)
	}
	if search := c.Query("search"); search != "" {
		like := "%" + strings.ToLower(search) + "%"
		q = q.Where("LOWER(name) LIKE ? OR LOWER(description) LIKE ?", like, like)
	}

	var projects []models.Project
	if err := q.Order("created_at DESC").Find(&projects).Error; err != nil {
		response.Err(c, http.StatusInternalServerError, "failed to fetch projects")
		return
	}
	response.OK(c, "projects fetched", projects)
}

// Create — POST /api/v1/projects  [admin, manager]
func (h *Handler) Create(c *gin.Context) {
	var req projectReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Err(c, http.StatusBadRequest, "invalid request body")
		return
	}

	if field, msg := req.validate(); msg != "" {
		response.FieldErr(c, field, msg)
		return
	}

	// Business rule: managers cannot create duplicate-named projects they own
	var dup models.Project
	if h.db.Where("name = ? AND owner_id = ?", req.Name, c.GetString("user_id")).First(&dup).Error == nil {
		response.FieldErr(c, "name", "you already have a project with this name")
		return
	}

	p := models.Project{
		Name:        req.Name,
		Description: strings.TrimSpace(req.Description),
		Status:      models.ProjectActive,
		OwnerID:     c.GetString("user_id"),
	}
	if req.Status != "" {
		p.Status = models.ProjectStatus(req.Status)
	}
	if req.Deadline != nil {
		t, _ := time.Parse("2006-01-02", *req.Deadline)
		p.Deadline = &t
	}

	if err := h.db.Create(&p).Error; err != nil {
		response.Err(c, http.StatusInternalServerError, "failed to create project")
		return
	}
	h.db.Preload("Owner").First(&p, "id = ?", p.ID)
	response.Created(c, "project created", p)
}

// GetByID — GET /api/v1/projects/:id  [auth]
func (h *Handler) GetByID(c *gin.Context) {
	var p models.Project
	if err := h.db.Preload("Owner").Preload("Tasks.Assignee").First(&p, "id = ?", c.Param("id")).Error; err != nil {
		response.Err(c, http.StatusNotFound, "project not found")
		return
	}
	response.OK(c, "project fetched", p)
}

// Update — PUT /api/v1/projects/:id  [admin, manager + owner check]
func (h *Handler) Update(c *gin.Context) {
	var p models.Project
	if err := h.db.First(&p, "id = ?", c.Param("id")).Error; err != nil {
		response.Err(c, http.StatusNotFound, "project not found")
		return
	}

	// Business rule: managers can only edit their own projects
	if c.GetString("user_role") == "manager" && p.OwnerID != c.GetString("user_id") {
		response.Err(c, http.StatusForbidden, "managers can only edit their own projects")
		return
	}

	var req projectReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Err(c, http.StatusBadRequest, "invalid request body")
		return
	}
	if field, msg := req.validate(); msg != "" {
		response.FieldErr(c, field, msg)
		return
	}

	// Business rule: cannot un-complete a project back to active without admin
	if p.Status == "completed" && req.Status == "active" && c.GetString("user_role") != "admin" {
		response.Err(c, http.StatusForbidden, "only admins can reopen completed projects")
		return
	}

	p.Name        = req.Name
	p.Description = strings.TrimSpace(req.Description)
	if req.Status != "" {
		p.Status = models.ProjectStatus(req.Status)
	}
	if req.Deadline != nil {
		t, _ := time.Parse("2006-01-02", *req.Deadline)
		p.Deadline = &t
	}

	if err := h.db.Save(&p).Error; err != nil {
		response.Err(c, http.StatusInternalServerError, "failed to update project")
		return
	}
	h.db.Preload("Owner").First(&p, "id = ?", p.ID)
	response.OK(c, "project updated", p)
}

// Delete — DELETE /api/v1/projects/:id  [admin only]
func (h *Handler) Delete(c *gin.Context) {
	var p models.Project
	if err := h.db.First(&p, "id = ?", c.Param("id")).Error; err != nil {
		response.Err(c, http.StatusNotFound, "project not found")
		return
	}

	// Business rule: delete project's tasks first (cascade)
	h.db.Where("project_id = ?", p.ID).Delete(&models.Task{})

	if err := h.db.Delete(&p).Error; err != nil {
		response.Err(c, http.StatusInternalServerError, "failed to delete project")
		return
	}
	response.NoContent(c)
}

// DashboardStats — GET /api/v1/dashboard/stats  [auth]
func (h *Handler) DashboardStats(c *gin.Context) {
	var (
		totalProjects, activeProjects int64
		totalTasks, doneTasks, inProgressTasks, totalMembers int64
	)
	h.db.Model(&models.Project{}).Count(&totalProjects)
	h.db.Model(&models.Project{}).Where("status = ?", "active").Count(&activeProjects)
	h.db.Model(&models.Task{}).Count(&totalTasks)
	h.db.Model(&models.Task{}).Where("status = ?", "done").Count(&doneTasks)
	h.db.Model(&models.Task{}).Where("status = ?", "in_progress").Count(&inProgressTasks)
	h.db.Model(&models.User{}).Count(&totalMembers)

	var recentProjects []models.Project
	h.db.Preload("Owner").Order("created_at DESC").Limit(5).Find(&recentProjects)

	// Task breakdown by priority
	type PriorityCount struct {
		Priority string
		Count    int64
	}
	var priorityCounts []PriorityCount
	h.db.Model(&models.Task{}).
		Select("priority, count(*) as count").
		Group("priority").
		Scan(&priorityCounts)

	response.OK(c, "stats fetched", gin.H{
		"total_projects":    totalProjects,
		"active_projects":   activeProjects,
		"total_tasks":       totalTasks,
		"done_tasks":        doneTasks,
		"in_progress_tasks": inProgressTasks,
		"todo_tasks":        totalTasks - doneTasks - inProgressTasks,
		"total_members":     totalMembers,
		"recent_projects":   recentProjects,
		"priority_breakdown": priorityCounts,
	})
}
