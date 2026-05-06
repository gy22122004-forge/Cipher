package database

import (
	"github.com/ethara/backend/internal/models"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func Init() (*gorm.DB, error) {
	db, err := gorm.Open(sqlite.Open("ethara.db"), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		return nil, err
	}
	return db, nil
}

func Migrate(db *gorm.DB) error {
	return db.AutoMigrate(&models.User{}, &models.Project{}, &models.Task{})
}
