import { useEffect, useMemo, useState } from "react";
import api from "../services/api";

const ALL_TIMES = [
  "05:00", "06:00", "07:00", "08:00", "09:00", "10:00",
  "11:00", "12:00", "13:00", "14:00", "15:00", "16:00",
  "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"
];

function timeToMinutes(time) {
  const [h, m] = time.split(":").map(Number);
  return h * 60 + m;
}

function getTimesBetween(open, close) {
  const openMin = timeToMinutes(open);
  const closeMin = timeToMinutes(close);
  return ALL_TIMES.filter((t) => {
    const min = timeToMinutes(t);
    return min >= openMin && min <= closeMin;
  });
}

function isOverlap(aStart, aEnd, bStart, bEnd) {
  const a1 = timeToMinutes(aStart);
  const a2 = timeToMinutes(aEnd);
  const b1 = timeToMinutes(bStart);
  const b2 = timeToMinutes(bEnd);
  return a1 < b2 && b1 < a2;
}

export default function CourtsPage() {
  const [courts, setCourts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [editingCourtId, setEditingCourtId] = useState(null);
  const [expandedCourtId, setExpandedCourtId] = useState(null);

  const [form, setForm] = useState({
    name: "",
    description: "",
    openTime: "06:00",
    closeTime: "22:00",
    status: "AVAILABLE",
  });

  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState("");
  const [priceSlots, setPriceSlots] = useState([
    { startTime: "06:00", endTime: "07:00", price: "" }
  ]);

  const availableTimes = useMemo(() => {
    return getTimesBetween(form.openTime, form.closeTime);
  }, [form.openTime, form.closeTime]);

  const fetchCourts = async () => {
    try {
      setLoading(true);
      const res = await api.get("/courts");
      setCourts(res.data?.data || []);
    } catch (err) {
      console.error(err);
      setCourts([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCourts();
  }, []);

  useEffect(() => {
    if (imageFile) {
      const url = URL.createObjectURL(imageFile);
      setImagePreview(url);
      return () => URL.revokeObjectURL(url);
    } else {
      setImagePreview("");
    }
  }, [imageFile]);

  const resetForm = () => {
    setForm({
      name: "",
      description: "",
      openTime: "06:00",
      closeTime: "22:00",
      status: "AVAILABLE",
    });
    setImageFile(null);
    setImagePreview("");
    setPriceSlots([{ startTime: "06:00", endTime: "07:00", price: "" }]);
    setEditingCourtId(null);
    setError("");
  };

  const handleBasicChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));

    if (name === "openTime" || name === "closeTime") {
      setPriceSlots([]);
    }
  };

  const handleSlotChange = (index, field, value) => {
    const updated = [...priceSlots];
    updated[index][field] = value;
    setPriceSlots(updated);
  };

  const addPriceSlot = () => {
    if (!form.openTime || !form.closeTime) return;

    const times = getTimesBetween(form.openTime, form.closeTime);
    if (times.length < 2) return;

    setPriceSlots((prev) => [
      ...prev,
      {
        startTime: times[0],
        endTime: times[1],
        price: "",
      },
    ]);
  };

  const removePriceSlot = (index) => {
    setPriceSlots((prev) => prev.filter((_, i) => i !== index));
  };

  const validateSlots = () => {
    if (priceSlots.length === 0) {
      return "Vui lòng thêm ít nhất 1 mức giá";
    }

    for (let i = 0; i < priceSlots.length; i++) {
      const slot = priceSlots[i];

      if (!slot.startTime || !slot.endTime || !slot.price) {
        return `Mức giá ${i + 1} chưa đủ thông tin`;
      }

      if (timeToMinutes(slot.startTime) >= timeToMinutes(slot.endTime)) {
        return `Mức giá ${i + 1} có giờ bắt đầu phải nhỏ hơn giờ kết thúc`;
      }

      if (
        timeToMinutes(slot.startTime) < timeToMinutes(form.openTime) ||
        timeToMinutes(slot.endTime) > timeToMinutes(form.closeTime)
      ) {
        return `Mức giá ${i + 1} phải nằm trong giờ mở cửa và đóng cửa`;
      }

      if (Number(slot.price) <= 0) {
        return `Mức giá ${i + 1} không hợp lệ`;
      }
    }

    for (let i = 0; i < priceSlots.length; i++) {
      for (let j = i + 1; j < priceSlots.length; j++) {
        if (
          isOverlap(
            priceSlots[i].startTime,
            priceSlots[i].endTime,
            priceSlots[j].startTime,
            priceSlots[j].endTime
          )
        ) {
          return `Mức giá ${i + 1} bị trùng giờ với mức giá ${j + 1}`;
        }
      }
    }

    return "";
  };

  const handleCreateOrUpdate = async (e) => {
    e.preventDefault();
    setError("");

    if (!form.name.trim()) {
      setError("Vui lòng nhập tên sân");
      return;
    }

    if (!form.openTime || !form.closeTime) {
      setError("Vui lòng chọn giờ mở cửa và đóng cửa");
      return;
    }

    if (timeToMinutes(form.openTime) >= timeToMinutes(form.closeTime)) {
      setError("Giờ mở cửa phải nhỏ hơn giờ đóng cửa");
      return;
    }

    const slotError = validateSlots();
    if (slotError) {
      setError(slotError);
      return;
    }

    try {
      setSubmitting(true);

      const payload = new FormData();
      payload.append("name", form.name.trim());
      payload.append("description", form.description.trim());
      payload.append("openTime", form.openTime);
      payload.append("closeTime", form.closeTime);
      payload.append("status", form.status);
      payload.append(
        "priceSlots",
        JSON.stringify(
          priceSlots.map((slot) => ({
            startTime: slot.startTime,
            endTime: slot.endTime,
            price: Number(slot.price),
          }))
        )
      );

      if (imageFile) {
        payload.append("image", imageFile);
      }

      if (editingCourtId) {
        await api.put(`/courts/${editingCourtId}`, payload, {
          headers: { "Content-Type": "multipart/form-data" },
        });
      } else {
        await api.post("/courts", payload, {
          headers: { "Content-Type": "multipart/form-data" },
        });
      }

      resetForm();
      setShowForm(false);
      fetchCourts();
    } catch (err) {
      console.error(err);
      setError(err.response?.data?.message || "Lưu sân thất bại");
    } finally {
      setSubmitting(false);
    }
  };

  const handleEdit = (court) => {
    setShowForm(true);
    setEditingCourtId(court.id);

    setForm({
      name: court.name || "",
      description: court.description || "",
      openTime: court.openTime || "06:00",
      closeTime: court.closeTime || "22:00",
      status: court.status || "AVAILABLE",
    });

    setImageFile(null);
    setImagePreview(court.imageUrl || "");
    setPriceSlots(
      court.priceSlots?.length
        ? court.priceSlots.map((slot) => ({
            startTime: slot.startTime,
            endTime: slot.endTime,
            price: slot.price,
          }))
        : [{ startTime: "06:00", endTime: "07:00", price: "" }]
    );
  };

  const handleDelete = async (courtId) => {
    const confirmDelete = window.confirm("Bạn có chắc muốn xóa sân này?");
    if (!confirmDelete) return;

    try {
      await api.delete(`/courts/${courtId}`);
      fetchCourts();
    } catch (err) {
      console.error(err);
      alert(err.response?.data?.message || "Xóa sân thất bại");
    }
  };

  return (
    <div className="page-wrap">
      <div className="section-header">
        <h2>Danh sách sân</h2>
        <button
          className="primary-btn"
          onClick={() => {
            if (showForm) {
              setShowForm(false);
              resetForm();
            } else {
              setShowForm(true);
              resetForm();
            }
          }}
        >
          {showForm ? "Đóng form" : "Thêm sân"}
        </button>
      </div>

      {showForm && (
        <div className="court-form-card">
          <h3>{editingCourtId ? "Sửa sân" : "Thêm sân mới"}</h3>

          <form onSubmit={handleCreateOrUpdate} className="court-form">
            <div className="form-grid">
              <div className="form-group">
                <label>Tên sân</label>
                <input
                  name="name"
                  placeholder="Nhập tên sân"
                  value={form.name}
                  onChange={handleBasicChange}
                />
              </div>

              <div className="form-group">
                <label>Trạng thái</label>
                <select
                  name="status"
                  value={form.status}
                  onChange={handleBasicChange}
                >
                  <option value="AVAILABLE">AVAILABLE</option>
                  <option value="MAINTENANCE">MAINTENANCE</option>
                  <option value="CLOSED">CLOSED</option>
                </select>
              </div>

              <div className="form-group">
                <label>Giờ mở cửa</label>
                <select
                  name="openTime"
                  value={form.openTime}
                  onChange={handleBasicChange}
                >
                  {ALL_TIMES.map((time) => (
                    <option key={time} value={time}>
                      {time}
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label>Giờ đóng cửa</label>
                <select
                  name="closeTime"
                  value={form.closeTime}
                  onChange={handleBasicChange}
                >
                  {ALL_TIMES.map((time) => (
                    <option key={time} value={time}>
                      {time}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="form-group">
              <label>Mô tả sân</label>
              <textarea
                name="description"
                placeholder="Nhập mô tả sân"
                rows="4"
                value={form.description}
                onChange={handleBasicChange}
              />
            </div>

            <div className="form-group">
              <label>Ảnh sân</label>
              <input
                type="file"
                accept="image/*"
                onChange={(e) => setImageFile(e.target.files?.[0] || null)}
              />
              {imagePreview && (
                <img
                  src={imagePreview}
                  alt="preview"
                  className="court-preview-image"
                />
              )}
            </div>

            <div className="price-header">
              <h4>Mức giá theo giờ</h4>
              <button
                type="button"
                className="secondary-btn"
                onClick={addPriceSlot}
              >
                + Thêm mức giá
              </button>
            </div>

            {priceSlots.map((slot, index) => (
              <div key={index} className="price-slot-row">
                <div className="form-group">
                  <label>Từ giờ</label>
                  <select
                    value={slot.startTime}
                    onChange={(e) =>
                      handleSlotChange(index, "startTime", e.target.value)
                    }
                  >
                    {availableTimes.map((time) => (
                      <option key={time} value={time}>
                        {time}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label>Đến giờ</label>
                  <select
                    value={slot.endTime}
                    onChange={(e) =>
                      handleSlotChange(index, "endTime", e.target.value)
                    }
                  >
                    {availableTimes.map((time) => (
                      <option key={time} value={time}>
                        {time}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label>Giá</label>
                  <input
                    type="number"
                    placeholder="VD: 150000"
                    value={slot.price}
                    onChange={(e) =>
                      handleSlotChange(index, "price", e.target.value)
                    }
                  />
                </div>

                <div className="price-remove-wrap">
                  <button
                    type="button"
                    className="danger-btn"
                    onClick={() => removePriceSlot(index)}
                    disabled={priceSlots.length === 1}
                  >
                    Xóa
                  </button>
                </div>
              </div>
            ))}

            {error && <div className="error-box">{error}</div>}

            <div className="form-actions">
              <button type="submit" className="primary-btn" disabled={submitting}>
                {submitting
                  ? "Đang lưu..."
                  : editingCourtId
                  ? "Cập nhật sân"
                  : "Lưu sân"}
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="court-list-card">
        {loading ? (
          <p>Đang tải danh sách sân...</p>
        ) : courts.length === 0 ? (
          <p>Chưa có sân nào</p>
        ) : (
          <div className="court-grid">
            {courts.map((court) => {
              const isOpen = expandedCourtId === court.id;
              return (
                <div key={court.id} className="court-item-card compact-card">
                  <div className="court-item-top">
                    <div>
                      <h3>{court.name}</h3>
                      <p className="court-status">{court.status}</p>
                    </div>
                    {court.imageUrl && (
                      <img
                        src={court.imageUrl}
                        alt={court.name}
                        className="court-thumb"
                      />
                    )}
                  </div>

                  <div className="court-actions">
                    <button
                      type="button"
                      className="secondary-btn"
                      onClick={() => setExpandedCourtId(isOpen ? null : court.id)}
                    >
                      {isOpen ? "Thu gọn" : "Xem thêm"}
                    </button>
                    <button type="button" className="secondary-btn" onClick={() => handleEdit(court)}>
                      Sửa
                    </button>
                    <button type="button" className="danger-btn" onClick={() => handleDelete(court.id)}>
                      Xóa
                    </button>
                  </div>

                  {isOpen && (
                    <>
                      <p><strong>Mô tả:</strong> {court.description || "-"}</p>
                      <p><strong>Giờ hoạt động:</strong> {court.openTime} - {court.closeTime}</p>

                      <div className="price-list">
                        <strong>Bảng giá:</strong>
                        {court.priceSlots?.length ? (
                          <ul>
                            {court.priceSlots.map((slot, idx) => (
                              <li key={idx}>
                                {slot.startTime} - {slot.endTime}: {slot.price} VNĐ
                              </li>
                            ))}
                          </ul>
                        ) : (
                          <p>Chưa có bảng giá</p>
                        )}
                      </div>
                    </>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
