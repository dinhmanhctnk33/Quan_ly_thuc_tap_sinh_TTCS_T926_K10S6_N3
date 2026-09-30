package com.example.internmanagement.controller;

import com.example.internmanagement.dao.InternDocumentDAO;
import com.example.internmanagement.model.InternDocument;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.UUID;

@WebServlet({"/documents/upload", "/documents/review"})
@MultipartConfig(
    maxFileSize = 10 * 1024 * 1024,   // 10 MB
    maxRequestSize = 22 * 1024 * 1024 // 22 MB
)
public class DocumentServlet extends HttpServlet {

    private final InternDocumentDAO dao = new InternDocumentDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String servletPath = request.getServletPath();
        
        if (servletPath.endsWith("upload")) {
            request.getRequestDispatcher("/WEB-INF/views/screens/ui-08-document-upload.jsp")
                   .forward(request, response);
        } else {
            request.getRequestDispatcher("/WEB-INF/views/screens/ui-07-document-review.jsp")
                   .forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        String servletPath = request.getServletPath();

        if (servletPath.endsWith("review")) {
            handleReview(request, response);
        } else {
            handleUpload(request, response);
        }
    }

    private void handleReview(HttpServletRequest request, HttpServletResponse response) 
            throws IOException, ServletException {
        try {
            int documentId = Integer.parseInt(request.getParameter("documentId"));
            String status = request.getParameter("status");
            String reviewNote = request.getParameter("reviewNote");
            String internId = request.getParameter("internId");

            // Parse reviewerId nếu có truyền lên
            String reviewerIdParam = request.getParameter("reviewerId");
            Long reviewerId = (reviewerIdParam != null && !reviewerIdParam.isBlank()) 
                              ? Long.parseLong(reviewerIdParam) 
                              : null;

            dao.review(documentId, status, reviewNote, reviewerId);
            response.sendRedirect(request.getContextPath() + "/interns/profile?id=" + internId);

        } catch (Exception e) {
            request.setAttribute("error", "Lỗi xử lý duyệt tài liệu: " + e.getMessage());
            request.getRequestDispatcher("/WEB-INF/views/screens/ui-07-document-review.jsp")
                   .forward(request, response);
        }
    }

    private void handleUpload(HttpServletRequest request, HttpServletResponse response) 
            throws IOException, ServletException {
        try {
            String internIdParam = request.getParameter("internId");
            if (internIdParam == null || internIdParam.trim().isEmpty()) {
                throw new IllegalArgumentException("Thiếu thông tin thực tập sinh");
            }
            int internProfileId = Integer.parseInt(internIdParam);

            Part filePart = request.getPart("file");
            if (filePart == null || filePart.getSize() == 0) {
                throw new IllegalArgumentException("Vui lòng chọn tệp cần tải lên");
            }

            String originalFileName = filePart.getSubmittedFileName();
            if (originalFileName == null || !originalFileName.toLowerCase().endsWith(".pdf")) {
                throw new IllegalArgumentException("Chỉ chấp nhận tệp định dạng PDF");
            }

            String cleanedOriginalName = Paths.get(originalFileName).getFileName().toString();
            String storedFileName = UUID.randomUUID() + ".pdf";

            // Lưu tệp vào thư mục intern-uploads
            Path uploadDir = Paths.get(System.getProperty("catalina.base", System.getProperty("java.io.tmpdir")), "intern-uploads");
            Files.createDirectories(uploadDir);

            try (InputStream inputStream = filePart.getInputStream()) {
                Files.copy(inputStream, uploadDir.resolve(storedFileName), StandardCopyOption.REPLACE_EXISTING);
            }

            // Đường dẫn URL tương đối để truy cập file
            String fileUrl = "/uploads/" + storedFileName;

            // Lưu thông tin vào Database khớp với Model InternDocument
            InternDocument document = new InternDocument();
            document.setInternProfileId(internProfileId);
            document.setDocumentType(request.getParameter("documentType"));
            document.setFileName(cleanedOriginalName);
            document.setFileUrl(fileUrl);
            document.setFileSizeBytes(filePart.getSize());
            document.setUploadedAt(LocalDateTime.now());

            dao.add(document);

            response.sendRedirect(request.getContextPath() + "/interns/profile?id=" + internProfileId + "&uploaded=1");

        } catch (Exception e) {
            request.setAttribute("error", e.getMessage());
            request.getRequestDispatcher("/WEB-INF/views/screens/ui-08-document-upload.jsp")
                   .forward(request, response);
        }
    }
}