package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ProjectStatus string

const (
	ProjectActive    ProjectStatus = "active"
	ProjectCompleted ProjectStatus = "completed"
	ProjectOnHold    ProjectStatus = "on_hold"
)

type Project struct {
	ID          string        `gorm:"primaryKey" json:"id"`
	Name        string        `gorm:"not null" json:"name"`
	Description string        `json:"description"`
	Status      ProjectStatus `gorm:"default:'active'" json:"status"`
	OwnerID     string        `gorm:"not null" json:"owner_id"`
	Owner       *User         `gorm:"foreignKey:OwnerID" json:"owner,omitempty"`
	Deadline    *time.Time    `json:"deadline"`
	Tasks       []Task        `gorm:"foreignKey:ProjectID" json:"tasks,omitempty"`
	CreatedAt   time.Time     `json:"created_at"`
	UpdatedAt   time.Time     `json:"updated_at"`
}

func (p *Project) BeforeCreate(tx *gorm.DB) error {
	if p.ID == "" {
		p.ID = uuid.New().String()
	}
	return nil
}
