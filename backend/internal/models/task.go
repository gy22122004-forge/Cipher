package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type TaskStatus string
type TaskPriority string

const (
	TaskTodo       TaskStatus = "todo"
	TaskInProgress TaskStatus = "in_progress"
	TaskDone       TaskStatus = "done"

	PriorityLow    TaskPriority = "low"
	PriorityMedium TaskPriority = "medium"
	PriorityHigh   TaskPriority = "high"
)

type Task struct {
	ID          string       `gorm:"primaryKey" json:"id"`
	Title       string       `gorm:"not null" json:"title"`
	Description string       `json:"description"`
	Status      TaskStatus   `gorm:"default:'todo'" json:"status"`
	Priority    TaskPriority `gorm:"default:'medium'" json:"priority"`
	ProjectID   string       `gorm:"not null" json:"project_id"`
	Project     *Project     `gorm:"foreignKey:ProjectID" json:"project,omitempty"`
	AssigneeID  *string      `json:"assignee_id"`
	Assignee    *User        `gorm:"foreignKey:AssigneeID" json:"assignee,omitempty"`
	CreatedAt   time.Time    `json:"created_at"`
	UpdatedAt   time.Time    `json:"updated_at"`
}

func (t *Task) BeforeCreate(tx *gorm.DB) error {
	if t.ID == "" {
		t.ID = uuid.New().String()
	}
	return nil
}
