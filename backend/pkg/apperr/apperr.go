// Package apperr provides structured, consistent error responses for the API.
package apperr

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// AppError is a machine-readable error with an HTTP code and a user-facing message.
type AppError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Field   string `json:"field,omitempty"` // which field caused the error (for 400s)
}

func (e *AppError) Error() string { return e.Message }

// Predefined errors
var (
	ErrUnauthorized = &AppError{Code: http.StatusUnauthorized, Message: "authentication required"}
	ErrForbidden    = &AppError{Code: http.StatusForbidden, Message: "insufficient permissions"}
	ErrNotFound     = &AppError{Code: http.StatusNotFound, Message: "resource not found"}
	ErrConflict     = &AppError{Code: http.StatusConflict, Message: "resource already exists"}
	ErrInternal     = &AppError{Code: http.StatusInternalServerError, Message: "internal server error"}
)

func BadRequest(msg string) *AppError {
	return &AppError{Code: http.StatusBadRequest, Message: msg}
}

func FieldError(field, msg string) *AppError {
	return &AppError{Code: http.StatusBadRequest, Message: msg, Field: field}
}

// Respond sends a structured error JSON response.
func Respond(c *gin.Context, err *AppError) {
	c.JSON(err.Code, gin.H{
		"success": false,
		"error": gin.H{
			"code":    err.Code,
			"message": err.Message,
			"field":   err.Field,
		},
	})
}
