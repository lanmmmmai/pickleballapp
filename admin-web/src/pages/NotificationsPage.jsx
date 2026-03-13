import { useEffect, useState } from "react";
import api from "../services/api";

const defaultForm = {
  title: "",
  content: "",
  type: "SYSTEM",
  isActive: true,
};

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  const [form, setForm] = useState(defaultForm);
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState("");

  const fetchNotifications = async () => {
    try {
      setLoading(true);
      setError("");
      const res = await api.get("/notifications");
      setNotifications(res.data?.data || []);
    } catch (err) {
      console.error(err);
      setError("Không tải được danh sách thông báo");
      setNotifications([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
  }, []);

  useEffect(() => {
    if (imageFile) {
      const url = URL.createObjectURL(imageFile);
      setImagePreview(url);
      return () => URL.revokeObjectURL(url);
    }
  }, [imageFile]);

  const resetForm = () => {
    setForm(defaultForm);
    setImageFile(null);
    setImagePreview("");
    setEditingId(null);
    setShowForm(false);
    setError("");
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    if (!form.title.trim() || !form.content.trim()) {
      setError("Vui lòng nhập tiêu đề và nội dung");
      return;
    }

    try {
      setSubmitting(true);

      const payload = new FormData();
      payload.append("title", form.title.trim());
      payload.append("content", form.content.trim());
      payload.append("type", form.type);
      payload.append("isActive", String(form.isActive));

      if (imageFile) {
        payload.append("image", imageFile);
      }

      if (editingId) {
        await api.put(`/notifications/${editingId}`, payload, {
          headers: { "Content-Type": "multipart/form-data" },
        });
      } else {
        await api.post("/notifications", payload, {
          headers: { "Content-Type": "multipart/form-data" },
        });
      }

      resetForm();
      fetchNotifications();
    } catch (err) {
      console.error(err);
      setError(err.response?.data?.message || "Lưu thông báo thất bại");
    } finally {
      setSubmitting(false);
    }
  };

  const handleEdit = (notification) => {
    setShowForm(true);
    setEditingId(notification.id);
    setForm({
      title: notification.title || "",
      content: notification.content || "",
      type: notification.type || "SYSTEM",
      isActive: !!notification.isActive,
    });
    setImageFile(null);
    setImagePreview(notification.imageUrl ? `http://127.0.0.1:3000${notification.imageUrl}` : "");
    setError("");
  };

  const handleDelete = async (id) => {
    const ok = window.confirm("Bạn có chắc muốn xóa thông báo này?");
    if (!ok) return;

    try {
      await api.delete(`/notifications/${id}`);
      fetchNotifications();
    } catch (err) {
      console.error(err);
      alert(err.response?.data?.message || "Xóa thông báo thất bại");
    }
  };

  return (
    <div className="page-wrap">
      <div className="section-header">
        <h2>Quản lý thông báo</h2>
        <button
          className="primary-btn"
          onClick={() => {
            if (showForm) {
              resetForm();
            } else {
              setShowForm(true);
              setEditingId(null);
              setForm(defaultForm);
            }
          }}
        >
          {showForm ? "Đóng form" : "Thêm thông báo"}
        </button>
      </div>

      {showForm && (
        <div className="court-form-card">
          <h3>{editingId ? "Sửa thông báo" : "Thêm thông báo mới"}</h3>

          <form onSubmit={handleSubmit} className="court-form">
            <div className="form-grid">
              <div className="form-group">
                <label>Tiêu đề</label>
                <input
                  name="title"
                  placeholder="Nhập tiêu đề thông báo"
                  value={form.title}
                  onChange={handleChange}
                />
              </div>

              <div className="form-group">
                <label>Loại thông báo</label>
                <select
                  name="type"
                  value={form.type}
                  onChange={handleChange}
                >
                  <option value="SYSTEM">SYSTEM</option>
                  <option value="PROMOTION">PROMOTION</option>
                  <option value="EVENT">EVENT</option>
                </select>
              </div>
            </div>

            <div className="form-group">
              <label>Nội dung</label>
              <textarea
                name="content"
                rows="5"
                placeholder="Nhập nội dung thông báo"
                value={form.content}
                onChange={handleChange}
              />
            </div>

            <div className="form-grid">
              <div className="form-group">
                <label>Trạng thái hiển thị</label>
                <select
                  value={String(form.isActive)}
                  onChange={(e) =>
                    setForm((prev) => ({
                      ...prev,
                      isActive: e.target.value === "true",
                    }))
                  }
                >
                  <option value="true">Hiển thị</option>
                  <option value="false">Ẩn</option>
                </select>
              </div>

              <div className="form-group">
                <label>Ảnh thông báo</label>
                <input
                  type="file"
                  accept="image/*"
                  onChange={(e) => setImageFile(e.target.files?.[0] || null)}
                />
              </div>
            </div>

            {imagePreview && (
              <img
                src={imagePreview}
                alt="preview"
                className="court-preview-image"
              />
            )}

            {error && <div className="error-box">{error}</div>}

            <div className="form-actions">
              <button type="submit" className="primary-btn" disabled={submitting}>
                {submitting
                  ? "Đang lưu..."
                  : editingId
                  ? "Cập nhật thông báo"
                  : "Tạo thông báo"}
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="court-list-card">
        {loading ? (
          <p>Đang tải danh sách thông báo...</p>
        ) : notifications.length === 0 ? (
          <p>Chưa có thông báo nào</p>
        ) : (
          <div className="court-grid">
            {notifications.map((item) => (
              <div key={item.id} className="court-item-card">
                <div className="court-item-top">
                  <div>
                    <h3>{item.title}</h3>
                    <p className="court-status">{item.type}</p>
                  </div>
                  {item.imageUrl && (
                    <img
                      src={`http://127.0.0.1:3000${item.imageUrl}`}
                      alt={item.title}
                      className="court-thumb"
                    />
                  )}
                </div>

                <p><strong>Nội dung:</strong> {item.content}</p>
                <p>
                  <strong>Hiển thị:</strong>{" "}
                  {item.isActive ? "Có" : "Không"}
                </p>
                <p>
                  <strong>Ngày tạo:</strong>{" "}
                  {new Date(item.createdAt).toLocaleString("vi-VN")}
                </p>

                <div className="court-actions">
                  <button
                    className="secondary-btn"
                    onClick={() => handleEdit(item)}
                  >
                    Sửa
                  </button>
                  <button
                    className="danger-btn"
                    onClick={() => handleDelete(item.id)}
                  >
                    Xóa
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}