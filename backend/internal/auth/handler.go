package auth

import (
	"net/http"
	"strings"
	"unicode"

	"github.com/ethara/backend/internal/models"
	jwtpkg "github.com/ethara/backend/pkg/jwt"
	"github.com/ethara/backend/pkg/response"
	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type Handler struct{ db *gorm.DB }

func NewHandler(db *gorm.DB) *Handler { return &Handler{db: db} }

// ── Request types ──────────────────────────────────────────────────────────

type registerReq struct {
	Name     string `json:"name"     binding:"required"`
	Email    string `json:"email"    binding:"required"`
	Password string `json:"password" binding:"required"`
}

type loginReq struct {
	Email    string `json:"email"    binding:"required"`
	Password string `json:"password" binding:"required"`
}

// ── Validators ─────────────────────────────────────────────────────────────

func validatePassword(pw string) string {
	if len(pw) < 6 {
		return "password must be at least 6 characters"
	}
	if len(pw) > 72 {
		return "password must be at most 72 characters"
	}
	var hasUpper, hasDigit bool
	for _, r := range pw {
		if unicode.IsUpper(r) {
			hasUpper = true
		}
		if unicode.IsDigit(r) {
			hasDigit = true
		}
	}
	if !hasUpper {
		return "password must contain at least one uppercase letter"
	}
	if !hasDigit {
		return "password must contain at least one digit"
	}
	return ""
}

func validateEmail(email string) string {
	email = strings.TrimSpace(email)
	if email == "" {
		return "email is required"
	}
	if !strings.Contains(email, "@") || !strings.Contains(email, ".") {
		return "invalid email address"
	}
	if len(email) > 254 {
		return "email address is too long"
	}
	return ""
}

// ── Handlers ───────────────────────────────────────────────────────────────

// Register godoc
// POST /api/v1/auth/register
// Public — creates a new user account (role: member by default).
func (h *Handler) Register(c *gin.Context) {
	var req registerReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Err(c, http.StatusBadRequest, "request body is invalid JSON")
		return
	}

	req.Name  = strings.TrimSpace(req.Name)
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))

	// Field-level validation
	if len(req.Name) < 2 {
		response.FieldErr(c, "name", "name must be at least 2 characters")
		return
	}
	if msg := validateEmail(req.Email); msg != "" {
		response.FieldErr(c, "email", msg)
		return
	}
	if msg := validatePassword(req.Password); msg != "" {
		response.FieldErr(c, "password", msg)
		return
	}

	// Uniqueness check
	var existing models.User
	if h.db.Where("email = ?", req.Email).First(&existing).Error == nil {
		response.FieldErr(c, "email", "this email is already registered")
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		response.Err(c, http.StatusInternalServerError, "failed to process credentials")
		return
	}

	user := models.User{
		Name:         req.Name,
		Email:        req.Email,
		PasswordHash: string(hash),
		Role:         models.RoleMember,
	}
	if err := h.db.Create(&user).Error; err != nil {
		response.Err(c, http.StatusInternalServerError, "failed to create account")
		return
	}

	token, err := jwtpkg.Generate(user.ID, user.Email, string(user.Role))
	if err != nil {
		response.Err(c, http.StatusInternalServerError, "failed to generate token")
		return
	}

	response.Created(c, "account created successfully", gin.H{"token": token, "user": user})
}

// Login godoc
// POST /api/v1/auth/login
// Public — authenticates a user and returns a JWT.
func (h *Handler) Login(c *gin.Context) {
	var req loginReq
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Err(c, http.StatusBadRequest, "request body is invalid JSON")
		return
	}

	req.Email = strings.ToLower(strings.TrimSpace(req.Email))

	if msg := validateEmail(req.Email); msg != "" {
		response.FieldErr(c, "email", msg)
		return
	}
	if req.Password == "" {
		response.FieldErr(c, "password", "password is required")
		return
	}

	var user models.User
	if err := h.db.Where("email = ?", req.Email).First(&user).Error; err != nil {
		// Use constant-time-safe generic message to prevent user enumeration
		response.Err(c, http.StatusUnauthorized, "invalid email or password")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		response.Err(c, http.StatusUnauthorized, "invalid email or password")
		return
	}

	token, err := jwtpkg.Generate(user.ID, user.Email, string(user.Role))
	if err != nil {
		response.Err(c, http.StatusInternalServerError, "failed to generate token")
		return
	}

	response.OK(c, "login successful", gin.H{"token": token, "user": user})
}

// Me godoc
// GET /api/v1/auth/me  [protected]
// Returns the currently authenticated user's profile.
func (h *Handler) Me(c *gin.Context) {
	userID := c.GetString("user_id")
	var user models.User
	if err := h.db.First(&user, "id = ?", userID).Error; err != nil {
		response.Err(c, http.StatusNotFound, "user not found")
		return
	}
	response.OK(c, "profile fetched", user)
}
