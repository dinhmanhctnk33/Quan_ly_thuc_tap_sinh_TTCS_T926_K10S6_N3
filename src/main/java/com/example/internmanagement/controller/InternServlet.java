package com.example.internmanagement.controller;

import com.example.internmanagement.dao.InternDocumentDAO;
import com.example.internmanagement.dao.InternProfileDAO;
import com.example.internmanagement.model.InternProfile;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet({"/home", "/interns", "/interns/new", "/interns/edit", "/interns/profile"})
public class InternServlet extends HttpServlet {

    private final InternProfileDAO profileDAO = new InternProfileDAO();
    private final InternDocumentDAO documentDAO = new InternDocumentDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String path = request.getServletPath();

        try {
            switch (path) {
                case "/home":
                    renderHome(request, response);
                    break;
                case "/interns":
                    renderInternList(request, response);
                    break;
                case "/interns/profile":
                    renderInternProfile(request, response);
                    break;
                case "/interns/edit":
                    renderInternEdit(request, response);
                    break;
                case "/interns/new":
                default:
                    renderInternCreate(request, response);
                    break;
            }
        } catch (SQLException | IllegalArgumentException e) {
            throw new ServletException("Lỗi hệ thống khi tải trang thực tập sinh", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        InternProfile profile = null;
        try {
            profile = parseProfileFromRequest(request);
            if (profile.getId() > 0) {
                profileDAO.update(profile);
            } else {
                profileDAO.insert(profile);
            }

            response.sendRedirect(request.getContextPath() + "/interns/profile?id=" + profile.getId() + "&success=1");

        } catch (SQLException | IllegalArgumentException e) {
            request.setAttribute("errorMessage", e.getMessage());
            if (profile == null) {
                profile = new InternProfile();
            }
            setFormAttributes(request, profile);
            request.getRequestDispatcher("/WEB-INF/views/screens/ui-05-intern-create.jsp")
                   .forward(request, response);
        }
    }

    // --- Các hàm điều hướng GET ---

    private void renderHome(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/views/screens/ui-02-dashboard.jsp")
               .forward(request, response);
    }

    private void renderInternList(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {
        String keyword = request.getParameter("q");
        List<InternProfile> list = profileDAO.searchInterns(keyword);

        request.setAttribute("interns", list);
        request.getRequestDispatcher("/WEB-INF/views/screens/ui-04-intern-list.jsp")
               .forward(request, response);
    }

    private void renderInternProfile(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException, SQLException {
        int internId = parseId(request);
        request.setAttribute("intern", profileDAO.getInternById(internId));
        request.setAttribute("documents", documentDAO.findByIntern(internId));

        request.getRequestDispatcher("/WEB-INF/views/screens/ui-06-intern-profile.jsp")
               .forward(request, response);
    }

    private void renderInternEdit(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException, SQLException {
        int internId = parseId(request);
        request.setAttribute("intern", profileDAO.getInternById(internId));

        request.getRequestDispatcher("/WEB-INF/views/screens/ui-05-intern-create.jsp")
               .forward(request, response);
    }

    private void renderInternCreate(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/views/screens/ui-05-intern-create.jsp")
               .forward(request, response);
    }

    // --- Các hàm Helper bổ trợ ---

    private InternProfile parseProfileFromRequest(HttpServletRequest request) throws SQLException {
        String rawId = request.getParameter("id");
        InternProfile profile;
        if (rawId != null && !rawId.isBlank()) {
            int id = Integer.parseInt(rawId);
            profile = profileDAO.getInternById(id);
            if (profile == null) {
                throw new IllegalArgumentException("Không tìm thấy hồ sơ thực tập sinh cần cập nhật.");
            }
        } else {
            profile = new InternProfile();
            profile.setUserId(parseOptionalId(request.getParameter("userId"), "Tài khoản thực tập sinh"));
        }

        setIfPresent(request, "internCode", profile::setInternCode);
        setIfPresent(request, "phoneNumber", profile::setPhoneNumber);
        setIfPresent(request, "universityName", profile::setUniversityName);
        setIfPresent(request, "majorName", profile::setMajorName);
        setIfPresent(request, "internshipStatus", profile::setInternshipStatus);

        if (isBlank(profile.getInternCode())) {
            throw new IllegalArgumentException("Mã thực tập sinh là bắt buộc.");
        }

        return profile;
    }

    private void setIfPresent(
            HttpServletRequest request,
            String parameterName,
            java.util.function.Consumer<String> setter) {
        String value = request.getParameter(parameterName);
        if (value != null) {
            setter.accept(value.trim());
        }
    }

    private int parseOptionalId(String value, String fieldName) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(fieldName + " là bắt buộc.");
        }
        try {
            int id = Integer.parseInt(value);
            if (id <= 0) {
                throw new IllegalArgumentException(fieldName + " không hợp lệ.");
            }
            return id;
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(fieldName + " không hợp lệ.", e);
        }
    }

    private void setFormAttributes(HttpServletRequest request, InternProfile profile) {
        request.setAttribute("internCode", profile.getInternCode());
        request.setAttribute("phoneNumber", profile.getPhoneNumber());
        request.setAttribute("universityName", profile.getUniversityName());
        request.setAttribute("majorName", profile.getMajorName());
        request.setAttribute("internshipStatus", profile.getInternshipStatus());
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private int parseId(HttpServletRequest request) {
        String idParam = request.getParameter("id");
        if (idParam == null || idParam.isBlank()) {
            throw new IllegalArgumentException("Thiếu tham số ID thực tập sinh");
        }
        return Integer.parseInt(idParam);
    }

}