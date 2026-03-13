import { useEffect, useState } from "react";
import api from "../services/api";

const defaultForm = {
  code: "",
  title: "",
  description: "",
  discountType: "PERCENT",
  discountValue: "",
  minOrderValue: "",
  coinCost: "",
  quantity: "",
  startDate: "",
  endDate: "",
  isActive: true,
};

export default function VouchersPage() {
  const [vouchers, setVouchers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [fetchError, setFetchError] = useState("");
  const [formError, setFormError] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [form, setForm] = useState(defaultForm);

  const fetchVouchers = async () => {
    try {
      setLoading(true);
      setFetchError("");
      const res = await api.get("/vouchers");
      setVouchers(res.data?.data || []);
    } catch (err) {
      console.error(err);
      setFetchError("Không tải được danh sách voucher");
      setVouchers([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVouchers();
  }, []);

  const resetForm = () => {
    setForm(defaultForm);
    setEditingId(null);
    setShowForm(false);
    setFormError("");
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
    setFormError("");

    if (
      !form.code.trim() ||
      !form.title.trim() ||
      !form.discountValue ||
      !form.coinCost ||
      !form.startDate ||
      !form.endDate
    ) {
      setFormError("Vui lòng nhập đầy đủ thông tin voucher");
      return;
    }

    try {
      setSubmitting(true);

      const payload = {
        ...form,
        isActive: !!form.isActive,
      };

      if (editingId) {
        await api.put(`/vouchers/${editingId}`, payload);
      } else {
        await api.post("/vouchers", payload);
      }

      resetForm();
      fetchVouchers();
    } catch (err) {
      console.error(err);
      setFormError(err.response?.data?.message || "Lưu voucher thất bại");
    } finally {
      setSubmitting(false);
    }
  };

  const handleEdit = (item) => {
    setShowForm(true);
    setEditingId(item.id);
    setForm({
      code: item.code || "",
      title: item.title || "",
      description: item.description || "",
      discountType: item.discountType || "PERCENT",
      discountValue: item.discountValue || "",
      minOrderValue: item.minOrderValue || "",
      coinCost: item.coinCost || "",
      quantity: item.quantity || "",
      startDate: item.startDate ? item.startDate.slice(0, 16) : "",
      endDate: item.endDate ? item.endDate.slice(0, 16) : "",
      isActive: !!item.isActive,
    });
    setFormError("");
  };

  const handleDelete = async (id) => {
    const ok = window.confirm("Bạn có chắc muốn xóa voucher này?");
    if (!ok) return;

    try {
      await api.delete(`/vouchers/${id}`);
      fetchVouchers();
    } catch (err) {
      console.error(err);
      alert(err.response?.data?.message || "Xóa voucher thất bại");
    }
  };

  return (
    <div className="page-wrap">
      <div className="section-header">
        <h2>Quản lý voucher</h2>
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
          {showForm ? "Đóng form" : "Thêm voucher"}
        </button>
      </div>

      {showForm && (
        <div className="court-form-card">
          <h3>{editingId ? "Sửa voucher" : "Thêm voucher mới"}</h3>

          <form onSubmit={handleSubmit} className="court-form">
            <div className="form-grid">
              <div className="form-group">
                <label>Mã voucher</label>
                <input
                  name="code"
                  value={form.code}
                  onChange={handleChange}
                  placeholder="VD: GIAM20"
                />
              </div>

              <div className="form-group">
                <label>Tiêu đề</label>
                <input
                  name="title"
                  value={form.title}
                  onChange={handleChange}
                  placeholder="Nhập tiêu đề voucher"
                />
              </div>
            </div>

            <div className="form-group">
              <label>Mô tả</label>
              <textarea
                name="description"
                rows="4"
                value={form.description}
                onChange={handleChange}
                placeholder="Nhập mô tả voucher"
              />
            </div>

            <div className="form-grid">
              <div className="form-group">
                <label>Loại giảm giá</label>
                <select
                  name="discountType"
                  value={form.discountType}
                  onChange={handleChange}
                >
                  <option value="PERCENT">Phần trăm</option>
                  <option value="FIXED">Số tiền cố định</option>
                </select>
              </div>

              <div className="form-group">
                <label>Giá trị giảm</label>
                <input
                  name="discountValue"
                  type="number"
                  value={form.discountValue}
                  onChange={handleChange}
                  placeholder="VD: 20 hoặc 50000"
                />
              </div>
            </div>

            <div className="form-grid">
              <div className="form-group">
                <label>Đơn tối thiểu</label>
                <input
                  name="minOrderValue"
                  type="number"
                  value={form.minOrderValue}
                  onChange={handleChange}
                  placeholder="VD: 200000"
                />
              </div>

              <div className="form-group">
                <label>Số xu đổi voucher</label>
                <input
                  name="coinCost"
                  type="number"
                  value={form.coinCost}
                  onChange={handleChange}
                  placeholder="VD: 300"
                />
              </div>
            </div>

            <div className="form-grid">
              <div className="form-group">
                <label>Số lượng voucher</label>
                <input
                  name="quantity"
                  type="number"
                  value={form.quantity}
                  onChange={handleChange}
                  placeholder="VD: 100"
                />
              </div>

              <div className="form-group">
                <label>Trạng thái</label>
                <select
                  value={String(form.isActive)}
                  onChange={(e) =>
                    setForm((prev) => ({
                      ...prev,
                      isActive: e.target.value === "true",
                    }))
                  }
                >
                  <option value="true">Đang hoạt động</option>
                  <option value="false">Tạm ẩn</option>
                </select>
              </div>
            </div>

            <div className="form-grid">
              <div className="form-group">
                <label>Ngày bắt đầu</label>
                <input
                  name="startDate"
                  type="datetime-local"
                  value={form.startDate}
                  onChange={handleChange}
                />
              </div>

              <div className="form-group">
                <label>Ngày kết thúc</label>
                <input
                  name="endDate"
                  type="datetime-local"
                  value={form.endDate}
                  onChange={handleChange}
                />
              </div>
            </div>

            {formError && <div className="error-box">{formError}</div>}

            <div className="form-actions">
              <button
                type="submit"
                className="primary-btn"
                disabled={submitting}
              >
                {submitting
                  ? "Đang lưu..."
                  : editingId
                  ? "Cập nhật voucher"
                  : "Tạo voucher"}
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="court-list-card">
        {fetchError && <div className="error-box">{fetchError}</div>}

        {loading ? (
          <p>Đang tải danh sách voucher...</p>
        ) : vouchers.length === 0 ? (
          <p>Chưa có voucher nào</p>
        ) : (
          <div className="court-grid">
            {vouchers.map((item) => {
              const redeemedCount = item.redeemedCount || 0;
              const usedCount = item.usedCount || 0;
              const quantity = item.quantity || 0;
              const remain = quantity - redeemedCount;

              return (
                <div key={item.id} className="court-item-card">
                  <div className="court-item-top">
                    <div>
                      <h3>{item.title}</h3>
                      <p className="court-status">{item.code}</p>
                    </div>
                  </div>

                  <p>
                    <strong>Mô tả:</strong> {item.description || "-"}
                  </p>
                  <p>
                    <strong>Loại giảm:</strong>{" "}
                    {item.discountType === "PERCENT"
                      ? "Phần trăm"
                      : "Số tiền"}
                  </p>
                  <p>
                    <strong>Giá trị giảm:</strong> {item.discountValue}
                  </p>
                  <p>
                    <strong>Đơn tối thiểu:</strong> {item.minOrderValue}
                  </p>
                  <p>
                    <strong>Số xu đổi:</strong> {item.coinCost || 0}
                  </p>
                  <p>
                    <strong>Tổng số lượng:</strong> {quantity}
                  </p>
                  <p>
                    <strong>Đã đổi:</strong> {redeemedCount}
                  </p>
                  <p>
                    <strong>Đã dùng:</strong> {usedCount}
                  </p>
                  <p>
                    <strong>Còn lại:</strong> {remain >= 0 ? remain : 0}
                  </p>
                  <p>
                    <strong>Trạng thái:</strong>{" "}
                    {item.isActive ? "Đang hoạt động" : "Tạm ẩn"}
                  </p>
                  <p>
                    <strong>Bắt đầu:</strong>{" "}
                    {item.startDate
                      ? new Date(item.startDate).toLocaleString("vi-VN")
                      : "-"}
                  </p>
                  <p>
                    <strong>Kết thúc:</strong>{" "}
                    {item.endDate
                      ? new Date(item.endDate).toLocaleString("vi-VN")
                      : "-"}
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
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}