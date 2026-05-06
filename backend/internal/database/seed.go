package database

import (
	"log"
	"time"

	"github.com/ethara/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func Seed(db *gorm.DB) {
	var count int64
	db.Model(&models.User{}).Count(&count)
	if count > 0 {
		return
	}
	log.Println("Seeding demo data...")

	hash := func(pw string) string {
		b, _ := bcrypt.GenerateFromPassword([]byte(pw), bcrypt.DefaultCost)
		return string(b)
	}

	admin := models.User{Name: "Admin User", Email: "admin@cipher.ai", PasswordHash: hash("admin123"), Role: models.RoleAdmin}
	manager := models.User{Name: "Project Manager", Email: "manager@cipher.ai", PasswordHash: hash("manager123"), Role: models.RoleManager}
	member := models.User{Name: "Team Member", Email: "member@cipher.ai", PasswordHash: hash("member123"), Role: models.RoleMember}

	db.Create(&admin)
	db.Create(&manager)
	db.Create(&member)

	deadline := time.Now().Add(30 * 24 * time.Hour)
	p1 := models.Project{Name: "Cipher Platform", Description: "Main product development", Status: models.ProjectActive, OwnerID: manager.ID, Deadline: &deadline}
	p2 := models.Project{Name: "Mobile App v2", Description: "Flutter redesign", Status: models.ProjectActive, OwnerID: manager.ID}
	db.Create(&p1)
	db.Create(&p2)

	tasks := []models.Task{
		{Title: "Setup Auth Flow", Description: "JWT login + register", Status: models.TaskDone, Priority: models.PriorityHigh, ProjectID: p1.ID, AssigneeID: &member.ID},
		{Title: "Design Dashboard", Description: "Analytics dashboard UI", Status: models.TaskInProgress, Priority: models.PriorityHigh, ProjectID: p1.ID, AssigneeID: &member.ID},
		{Title: "REST API Integration", Description: "Connect frontend to backend", Status: models.TaskTodo, Priority: models.PriorityMedium, ProjectID: p1.ID},
		{Title: "Write Unit Tests", Description: "Cover core services", Status: models.TaskTodo, Priority: models.PriorityLow, ProjectID: p1.ID},
		{Title: "Splash Screen", Description: "Animated intro screen", Status: models.TaskDone, Priority: models.PriorityMedium, ProjectID: p2.ID, AssigneeID: &member.ID},
		{Title: "Implement RBAC", Description: "Role-based access control", Status: models.TaskInProgress, Priority: models.PriorityHigh, ProjectID: p2.ID},
	}
	for _, t := range tasks {
		db.Create(&t)
	}
	log.Println("Seed complete. Demo accounts: admin@cipher.ai/admin123, manager@cipher.ai/manager123, member@cipher.ai/member123")
}
