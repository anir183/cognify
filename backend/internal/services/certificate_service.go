package services

import (
	"bytes"
	"fmt"
	"time"

	"github.com/jung-kurt/gofpdf"
)

// GenerateCertificatePDF creates a PDF certificate and returns the bytes
func GenerateCertificatePDF(studentName, courseName, achievement string, skills []string, congratMessage string, issuedAt time.Time) ([]byte, error) {
	pdf := gofpdf.New("L", "mm", "A4", "")
	pdf.AddPage()

	// Page dimensions
	pageWidth, pageHeight := 297.0, 210.0

	// Background gradient effect (dark theme)
	pdf.SetFillColor(10, 10, 15)
	pdf.Rect(0, 0, pageWidth, pageHeight, "F")

	// Border design
	pdf.SetDrawColor(0, 245, 255) // Cyan border
	pdf.SetLineWidth(2)
	pdf.Rect(10, 10, pageWidth-20, pageHeight-20, "D")

	// Inner border
	pdf.SetDrawColor(191, 0, 255) // Purple inner border
	pdf.SetLineWidth(0.5)
	pdf.Rect(15, 15, pageWidth-30, pageHeight-30, "D")

	// Header - COGNIFY logo
	pdf.SetTextColor(0, 245, 255)
	pdf.SetFont("Helvetica", "B", 28)
	pdf.SetXY(0, 25)
	pdf.CellFormat(pageWidth, 15, "COGNIFY", "", 0, "C", false, 0, "")

	// Subtitle
	pdf.SetTextColor(150, 150, 150)
	pdf.SetFont("Helvetica", "", 10)
	pdf.SetXY(0, 42)
	pdf.CellFormat(pageWidth, 8, "Level Up Your Mind", "", 0, "C", false, 0, "")

	// Certificate title
	pdf.SetTextColor(255, 255, 255)
	pdf.SetFont("Helvetica", "B", 24)
	pdf.SetXY(0, 58)
	pdf.CellFormat(pageWidth, 12, "CERTIFICATE OF COMPLETION", "", 0, "C", false, 0, "")

	// Achievement badge
	if achievement != "" {
		pdf.SetTextColor(191, 0, 255)
		pdf.SetFont("Helvetica", "I", 14)
		pdf.SetXY(0, 75)
		pdf.CellFormat(pageWidth, 10, achievement, "", 0, "C", false, 0, "")
	}

	// This certifies text
	pdf.SetTextColor(200, 200, 200)
	pdf.SetFont("Helvetica", "", 12)
	pdf.SetXY(0, 90)
	pdf.CellFormat(pageWidth, 8, "This is to certify that", "", 0, "C", false, 0, "")

	// Student name
	pdf.SetTextColor(0, 245, 255)
	pdf.SetFont("Helvetica", "B", 32)
	pdf.SetXY(0, 100)
	pdf.CellFormat(pageWidth, 18, studentName, "", 0, "C", false, 0, "")

	// Has successfully completed
	pdf.SetTextColor(200, 200, 200)
	pdf.SetFont("Helvetica", "", 12)
	pdf.SetXY(0, 120)
	pdf.CellFormat(pageWidth, 8, "has successfully completed the course", "", 0, "C", false, 0, "")

	// Course name
	pdf.SetTextColor(255, 255, 255)
	pdf.SetFont("Helvetica", "B", 20)
	pdf.SetXY(0, 132)
	pdf.CellFormat(pageWidth, 12, courseName, "", 0, "C", false, 0, "")

	// Skills section
	if len(skills) > 0 {
		pdf.SetTextColor(150, 150, 150)
		pdf.SetFont("Helvetica", "", 10)
		pdf.SetXY(0, 150)
		skillsText := "Skills Acquired: " + skills[0]
		for i := 1; i < len(skills); i++ {
			skillsText += " • " + skills[i]
		}
		pdf.CellFormat(pageWidth, 8, skillsText, "", 0, "C", false, 0, "")
	}

	// Date
	pdf.SetTextColor(100, 100, 100)
	pdf.SetFont("Helvetica", "", 10)
	pdf.SetXY(20, 175)
	pdf.CellFormat(100, 8, fmt.Sprintf("Issued: %s", issuedAt.Format("January 2, 2006")), "", 0, "L", false, 0, "")

	// Signature placeholder
	pdf.SetXY(pageWidth-120, 175)
	pdf.CellFormat(100, 8, "________________________", "", 0, "R", false, 0, "")
	pdf.SetXY(pageWidth-120, 182)
	pdf.CellFormat(100, 8, "Cognify Platform", "", 0, "R", false, 0, "")

	// Output to bytes
	var buf bytes.Buffer
	err := pdf.Output(&buf)
	if err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}
