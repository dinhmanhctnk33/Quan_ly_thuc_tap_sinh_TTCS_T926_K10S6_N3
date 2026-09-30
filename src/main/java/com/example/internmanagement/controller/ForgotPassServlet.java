package com.example.internmanagement.controller;

import com.example.internmanagement.dao.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;

@WebServlet("/forgot-pass")
public class ForgotPassServlet extends HttpServlet {
    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/views/screens/forgot-password.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String email = request.getParameter("email") == null ? "" : request.getParameter("email").trim();
        if (email.isEmpty()) {
            showForm(request, response, "Vui lòng nhập email.");
            return;
        }
        if (!userDAO.existsByEmail(email)) {
            showForm(request, response, "Không tìm thấy tài khoản dùng email này.");
            return;
        }
        String token = UUID.randomUUID().toString();
        if (!userDAO.updateResetToken(email, token)) {
            showForm(request, response, "Không thể tạo yêu cầu đặt lại mật khẩu. Vui lòng thử lại.");
            return;
        }
        String resetUrl = request.getRequestURL().toString().replace("/forgot-pass", "/reset-password") + "?token=" + token;
        request.setAttribute("resetUrl", resetUrl);
        request.getRequestDispatcher("/WEB-INF/views/screens/forgot-password-result.jsp").forward(request, response);
    }

    private void showForm(HttpServletRequest request, HttpServletResponse response, String error) throws ServletException, IOException {
        request.setAttribute("error", error);
        request.getRequestDispatcher("/WEB-INF/views/screens/forgot-password.jsp").forward(request, response);
    }
}
