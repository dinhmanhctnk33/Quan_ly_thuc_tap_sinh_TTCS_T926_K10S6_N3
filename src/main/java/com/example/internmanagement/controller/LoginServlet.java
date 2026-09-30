package com.example.internmanagement.controller;

import com.example.internmanagement.dao.UserDAO;
import com.example.internmanagement.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    private UserDAO userDAO;

    @Override
    public void init() {
        userDAO = new UserDAO();
    }

    // Hiển thị trang login
    @Override
    protected void doGet(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.getRequestDispatcher("/WEB-INF/views/screens/ui-01-login.jsp")
               .forward(request, response);
    }

    // Xử lý login
    @Override
    protected void doPost(HttpServletRequest request,
                           HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        // Kiểm tra dữ liệu nhập
        if (username == null || username.trim().isEmpty()
                || password == null || password.trim().isEmpty()) {

            request.setAttribute("error",
                    "Vui lòng nhập đầy đủ username và password.");

            request.getRequestDispatcher("/WEB-INF/views/screens/ui-01-login.jsp")
                   .forward(request, response);

            return;
        }

        // Kiểm tra tài khoản
        User user = userDAO.login(username, password);

        if (user != null) {

            // Tạo session
            HttpSession session = request.getSession();

            // Lưu user vào session
            session.setAttribute("user", user);
            session.setAttribute("currentUser", user);

            // Thời gian session: 30 phút
            session.setMaxInactiveInterval(30 * 60);

            // Chuyển đến trang chủ
            response.sendRedirect(request.getContextPath() + "/home");

        } else {

            request.setAttribute("error",
                    "Username hoặc password không chính xác.");

            request.getRequestDispatcher("/WEB-INF/views/screens/ui-01-login.jsp")
                   .forward(request, response);
        }
    }
}
