package auth

import (
	"strings"

	jwtpkg "github.com/ethara/backend/pkg/jwt"
	"github.com/ethara/backend/pkg/response"
	"github.com/gin-gonic/gin"
)

func Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" {
			response.Err(c, 401, "authorization header required")
			c.Abort()
			return
		}
		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			response.Err(c, 401, "invalid authorization format")
			c.Abort()
			return
		}
		claims, err := jwtpkg.Validate(parts[1])
		if err != nil {
			response.Err(c, 401, "invalid or expired token")
			c.Abort()
			return
		}
		c.Set("user_id", claims.UserID)
		c.Set("user_email", claims.Email)
		c.Set("user_role", claims.Role)
		c.Next()
	}
}

func RequireRole(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		role := c.GetString("user_role")
		for _, r := range roles {
			if r == role {
				c.Next()
				return
			}
		}
		response.Err(c, 403, "insufficient permissions")
		c.Abort()
	}
}
