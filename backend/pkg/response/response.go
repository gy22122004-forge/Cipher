package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Envelope is the standard API response shape.
type Envelope struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   *ErrDetail  `json:"error,omitempty"`
}

// ErrDetail carries machine-readable error information.
type ErrDetail struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Field   string `json:"field,omitempty"`
}

func OK(c *gin.Context, msg string, data interface{}) {
	c.JSON(http.StatusOK, Envelope{Success: true, Message: msg, Data: data})
}

func Created(c *gin.Context, msg string, data interface{}) {
	c.JSON(http.StatusCreated, Envelope{Success: true, Message: msg, Data: data})
}

func Err(c *gin.Context, status int, msg string) {
	c.JSON(status, Envelope{Success: false, Error: &ErrDetail{Code: status, Message: msg}})
}

func FieldErr(c *gin.Context, field, msg string) {
	c.JSON(http.StatusBadRequest, Envelope{
		Success: false,
		Error:   &ErrDetail{Code: http.StatusBadRequest, Message: msg, Field: field},
	})
}

func NoContent(c *gin.Context) {
	c.JSON(http.StatusOK, Envelope{Success: true, Message: "deleted successfully"})
}
