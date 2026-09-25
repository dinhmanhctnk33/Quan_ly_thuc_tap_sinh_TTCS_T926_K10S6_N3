/* =========================================================
   UI-05: THÊM MỚI HỒ SƠ THỰC TẬP SINH
  File: nhaphoso.js — toàn bộ logic tương tác & validate
   ========================================================= */

document.addEventListener("DOMContentLoaded", () => {

  /* =======================================================
     1. TAB SWITCHER — CHUYỂN TAB
     ======================================================= */
  const tabButtons = document.querySelectorAll(".tab-btn");
  const tabContents = document.querySelectorAll(".tab-content");

  function activateTab(tabId) {
    tabButtons.forEach((btn) => {
      const isActive = btn.dataset.tab === tabId;
      btn.classList.toggle("active", isActive);
      btn.setAttribute("aria-selected", isActive ? "true" : "false");
    });
    tabContents.forEach((content) => {
      content.classList.toggle("active", content.id === tabId);
      content.hidden = content.id !== tabId;
    });
  }

  tabButtons.forEach((btn) => {
    btn.addEventListener("click", () => activateTab(btn.dataset.tab));
  });

  /* =======================================================
     2. DRAG & DROP FILE EXCEL
     ======================================================= */
  const dropzone = document.getElementById("dropzone");
  const fileInput = document.getElementById("fileInput");
  const dropzoneFileName = document.getElementById("dropzoneFileName");
  const errFile = document.getElementById("err-file");
  const btnTemplate = document.getElementById("btnTemplate");

  const ALLOWED_EXTENSIONS = ["xlsx", "xls"];
  let selectedExcelFile = null; // lưu file Excel hợp lệ đã chọn (nếu có)

  function getFileExtension(fileName) {
    return fileName.split(".").pop().toLowerCase();
  }

  function showFileError(message) {
    errFile.textContent = message;
    errFile.classList.add("show");
    dropzone.classList.remove("file-accepted");
    dropzoneFileName.classList.remove("show");
    selectedExcelFile = null;
  }

  function acceptFile(file) {
    errFile.classList.remove("show");
    errFile.textContent = "";
    dropzone.classList.add("file-accepted");
    dropzoneFileName.textContent = `📄 Đã chọn: ${file.name}`;
    dropzoneFileName.classList.add("show");
    selectedExcelFile = file;
  }

  function handleSelectedFile(file) {
    if (!file) return;
    const ext = getFileExtension(file.name);
    if (!ALLOWED_EXTENSIONS.includes(ext)) {
      showFileError("File không hợp lệ, vui lòng chọn file Excel!");
      return;
    }
    acceptFile(file);
  }

  // Click vào khung dropzone -> mở hộp thoại chọn file
  dropzone.addEventListener("click", () => fileInput.click());
  dropzone.addEventListener("keydown", (e) => {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      fileInput.click();
    }
  });

  fileInput.addEventListener("change", (e) => {
    const file = e.target.files[0];
    handleSelectedFile(file);
  });

  // Hiệu ứng khi kéo file rê qua khung (dragenter/dragover)
  ["dragenter", "dragover"].forEach((eventName) => {
    dropzone.addEventListener(eventName, (e) => {
      e.preventDefault();
      e.stopPropagation();
      dropzone.classList.add("drag-over");
    });
  });

  // Bỏ hiệu ứng khi kéo file ra khỏi khung
  ["dragleave", "dragend"].forEach((eventName) => {
    dropzone.addEventListener(eventName, (e) => {
      e.preventDefault();
      e.stopPropagation();
      dropzone.classList.remove("drag-over");
    });
  });

  // Khi thả file vào khung
  dropzone.addEventListener("drop", (e) => {
    e.preventDefault();
    e.stopPropagation();
    dropzone.classList.remove("drag-over");

    const file = e.dataTransfer.files[0];
    handleSelectedFile(file);
  });

  // Nút "Tải file mẫu (.xlsx)" — chặn click lan ra dropzone (không mở hộp thoại chọn file)
  btnTemplate.addEventListener("click", (e) => {
    e.stopPropagation();
    // TODO: thay bằng đường dẫn file mẫu thật, ví dụ: window.location.href = "/templates/mau-ho-so-thuc-tap-sinh.xlsx";
    console.log("Yêu cầu tải file mẫu Excel (.xlsx) — gắn link file mẫu thật tại đây.");
  });

  /* =======================================================
     3. VALIDATION FORM
     ======================================================= */
  const form = document.getElementById("internForm");

  // Khai báo các trường cần validate: id input, có bắt buộc không, loại kiểm tra
  const fieldsConfig = [
    { id: "fullName", tab: "tab1", required: true, type: "text", label: "Họ và tên" },
    { id: "dob", tab: "tab1", required: true, type: "date", label: "Ngày sinh" },
    { id: "email", tab: "tab1", required: true, type: "email", label: "Email cá nhân" },
    { id: "phone", tab: "tab1", required: true, type: "phone", label: "Số điện thoại" },
    { id: "school", tab: "tab2", required: true, type: "text", label: "Trường Đại học/Cao đẳng" },
    { id: "major", tab: "tab2", required: false, type: "text", label: "Chuyên ngành" },
    { id: "department", tab: "tab3", required: false, type: "text", label: "Bộ phận tiếp nhận" },
    { id: "mentor", tab: "tab3", required: false, type: "text", label: "Mentor phụ trách" },
  ];

  const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,}$/;
  const PHONE_REGEX = /^[0-9]{10}$/;

  function setFieldError(fieldId, message) {
    const input = document.getElementById(fieldId);
    const errorEl = document.getElementById(`err-${fieldId}`);
    input.closest(".form-field").classList.add("has-error");
    errorEl.textContent = message;
    errorEl.classList.add("show");
  }

  function clearFieldError(fieldId) {
    const input = document.getElementById(fieldId);
    const errorEl = document.getElementById(`err-${fieldId}`);
    input.closest(".form-field").classList.remove("has-error");
    errorEl.textContent = "";
    errorEl.classList.remove("show");
  }

  function validateField(config) {
    const input = document.getElementById(config.id);
    const value = input.value.trim();

    clearFieldError(config.id);

    // 1) Kiểm tra bắt buộc
    if (config.required && !value) {
      setFieldError(config.id, `${config.label} không được để trống.`);
      return false;
    }

    // Nếu không bắt buộc và để trống -> hợp lệ, không cần kiểm tra định dạng
    if (!value) return true;

    // 2) Kiểm tra định dạng riêng theo loại field
    if (config.type === "email" && !EMAIL_REGEX.test(value)) {
      setFieldError(config.id, "Email không đúng định dạng (vd: ten@example.com).");
      return false;
    }

    if (config.type === "phone" && !PHONE_REGEX.test(value)) {
      setFieldError(config.id, "Số điện thoại phải gồm đúng 10 chữ số.");
      return false;
    }

    return true;
  }

  function validateForm() {
    let isValid = true;
    let firstInvalidTab = null;

    fieldsConfig.forEach((config) => {
      const fieldIsValid = validateField(config);
      if (!fieldIsValid) {
        isValid = false;
        if (!firstInvalidTab) firstInvalidTab = config.tab;
      }
    });

    // Nếu lỗi nằm ở tab đang ẩn -> tự động chuyển tới tab đó để người dùng thấy lỗi
    if (firstInvalidTab) {
      activateTab(firstInvalidTab);
    }

    return isValid;
  }

  /* =======================================================
     4. THU THẬP DỮ LIỆU & GỬI (MOCK API)
     ======================================================= */
  function collectFormData() {
    return {
      personalInfo: {
        fullName: document.getElementById("fullName").value.trim(),
        dob: document.getElementById("dob").value,
        email: document.getElementById("email").value.trim(),
        phone: document.getElementById("phone").value.trim(),
      },
      academicInfo: {
        school: document.getElementById("school").value.trim(),
        major: document.getElementById("major").value.trim(),
      },
      assignmentInfo: {
        department: document.getElementById("department").value,
        mentor: document.getElementById("mentor").value.trim(),
      },
      // File Excel (nếu HR chọn nhập nhanh bằng Excel thay vì nhập tay)
      excelFile: selectedExcelFile ? selectedExcelFile.name : null,
    };
  }

  function showToast(message) {
    const toast = document.getElementById("toast");
    toast.textContent = message;
    toast.classList.add("show");
    setTimeout(() => toast.classList.remove("show"), 2500);
  }

  form.addEventListener("submit", (e) => {
    e.preventDefault();

    const isValid = validateForm();
    if (!isValid) {
      showToast("Vui lòng kiểm tra lại các trường còn thiếu/sai.");
      return;
    }

    const formData = collectFormData();

    // ============================================================
    // 👉 VỊ TRÍ GỌI API THẬT: thay đoạn console.log bên dưới bằng
    // fetch("/api/interns", {
    //   method: "POST",
    //   headers: { "Content-Type": "application/json" },
    //   body: JSON.stringify(formData),
    // })
    //   .then((res) => res.json())
    //   .then((data) => { ... })
    //   .catch((err) => { ... });
    //
    // Hoặc dùng axios:
    // axios.post("/api/interns", formData).then(...).catch(...);
    // ============================================================
    console.log("formData gửi lên server:", formData);

    showToast("✅ Đã lưu hồ sơ thực tập sinh thành công!");
  });

  /* =======================================================
     5. NÚT HỦY
     ======================================================= */
  const btnCancel = document.getElementById("btnCancel");
  btnCancel.addEventListener("click", () => {
    const confirmed = confirm("Bạn có chắc muốn hủy? Toàn bộ dữ liệu đã nhập sẽ bị mất.");
    if (!confirmed) return;

    form.reset();
    fieldsConfig.forEach((config) => clearFieldError(config.id));
    errFile.classList.remove("show");
    dropzone.classList.remove("file-accepted");
    dropzoneFileName.classList.remove("show");
    selectedExcelFile = null;
    activateTab("tab1");
  });

});
