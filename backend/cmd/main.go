package main

import (
	"log"
	"os"
	"time"

	"github.com/ethara/backend/internal/auth"
	"github.com/ethara/backend/internal/database"
	"github.com/ethara/backend/internal/projects"
	"github.com/ethara/backend/internal/tasks"
	"github.com/ethara/backend/internal/users"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	db, err := database.Init()
	if err != nil {
		log.Fatal("DB init failed:", err)
	}
	if err := database.Migrate(db); err != nil {
		log.Fatal("Migration failed:", err)
	}
	database.Seed(db)

	// Release mode in production
	if os.Getenv("GIN_MODE") == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()
	r.Use(gin.Logger())
	r.Use(gin.Recovery())

	// CORS — allow all origins for dev; tighten for production
	r.Use(cors.New(cors.Config{
		AllowAllOrigins:  true,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "Accept"},
		ExposeHeaders:    []string{"Content-Length"},
		MaxAge:           12 * time.Hour,
	}))

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "ethara-api", "version": "1.0.0"})
	})

	authH    := auth.NewHandler(db)
	userH    := users.NewHandler(db)
	projectH := projects.NewHandler(db)
	taskH    := tasks.NewHandler(db)

	api := r.Group("/api/v1")

	// ── Public routes ──────────────────────────────────────────────────────
	api.POST("/auth/register", authH.Register)
	api.POST("/auth/login",    authH.Login)

	// ── Protected routes ───────────────────────────────────────────────────
	p := api.Group("/")
	p.Use(auth.Middleware())
	{
		// Auth
		p.GET("/auth/me", authH.Me)

		// Users
		p.GET("/users",             auth.RequireRole("admin"), userH.GetAll)
		p.GET("/users/me",          userH.GetMe)
		p.GET("/users/:id",         userH.GetByID)
		p.PUT("/users/:id/role",    auth.RequireRole("admin"), userH.UpdateRole)

		// Projects
		p.GET("/projects",         projectH.GetAll)
		p.POST("/projects",        auth.RequireRole("admin", "manager"), projectH.Create)
		p.GET("/projects/:id",     projectH.GetByID)
		p.PUT("/projects/:id",     auth.RequireRole("admin", "manager"), projectH.Update)
		p.DELETE("/projects/:id",  auth.RequireRole("admin"), projectH.Delete)

		// Tasks (nested under project)
		p.GET("/projects/:id/tasks",  taskH.GetByProject)
		p.POST("/projects/:id/tasks", auth.RequireRole("admin", "manager"), taskH.Create)

		// Tasks (standalone)
		p.GET("/tasks/:id",    taskH.GetByID)
		p.PUT("/tasks/:id",    taskH.Update)
		p.DELETE("/tasks/:id", auth.RequireRole("admin", "manager"), taskH.Delete)

		// Dashboard
		p.GET("/dashboard/stats", projectH.DashboardStats)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("🚀 Cipher API running at http://localhost:%s", port)
	log.Fatal(r.Run(":" + port))
}
