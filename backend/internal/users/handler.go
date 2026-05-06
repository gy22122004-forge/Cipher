package users

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

// GetAll — GET /api/v1/users  [admin]
func (h *Handler) GetAll(c *gin.Context) {
	q := h.db.Model(&models.User{})
	if role := c.Query("role"); role != "" {
		q = q.Where("role = ?", role)
	}
	if search := c.Query("search"); search != "" {
		like := "%" + strings.ToLower(search) + "%"
		q = q.Where("LOWER(name) LIKE ? OR LOWER(email) LIKE ?", like, like)
	}
	var users []models.User
	q.Order("created_at DESC").Find(&users)
	response.OK(c, "users fetched", users)
}

// GetMe — GET /api/v1/users/me  [auth]
func (h *Handler) GetMe(c *gin.Context) {
	var user models.User
	if err := h.db.First(&user, "id = ?", c.GetString("user_id")).Error; err != nil {
		response.Err(c, http.StatusNotFound, "user not found")
		return
	}
	response.OK(c, "profile fetched", user)
}

// GetByID — GET /api/v1/users/:id  [auth]
func (h *Handler) GetByID(c *gin.Context) {
	var user models.User
	if err := h.db.First(&user, "id = ?", c.Param("id")).Error; err != nil {
		response.Err(c, http.StatusNotFound, "user not found")
		return
	}
	response.OK(c, "user fetched", user)
}

// UpdateRole — PUT /api/v1/users/:id/role  [admin]
func (h *Handler) UpdateRole(c *gin.Context) {
	// Business rule: admin cannot change their own role
	if c.Param("id") == c.GetString("user_id") {
		response.Err(c, http.StatusConflict, "admins cannot change their own role")
		return
	}

	var req struct {
		Role string `json:"role"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Err(c, http.StatusBadRequest, "invalid request body")
		return
	}

	req.Role = strings.ToLower(strings.TrimSpace(req.Role))
	validRoles := map[string]bool{"admin": true, "manager": true, "member": true}
	if !validRoles[req.Role] {
		response.FieldErr(c, "role", "role must be one of: admin, manager, member")
		return
	}

	var user models.User
	if err := h.db.First(&user, "id = ?", c.Param("id")).Error; err != nil {
		response.Err(c, http.StatusNotFound, "user not found")
		return
	}

	if err := h.db.Model(&user).Update("role", req.Role).Error; err != nil {
		response.Err(c, http.StatusInternalServerError, "failed to update role")
		return
	}
	response.OK(c, "role updated successfully", user)
}
