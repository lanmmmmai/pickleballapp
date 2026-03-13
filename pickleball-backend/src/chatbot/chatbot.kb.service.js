const fs = require("fs");
const path = require("path");
const mammoth = require("mammoth");

let kbState = {
  loaded: false,
  rawText: "",
  chunks: [],
  loadedAt: null,
};

function normalizeText(text) {
  return (text || "")
    .replace(/\r/g, "\n")
    .replace(/\t/g, " ")
    .replace(/\u00a0/g, " ")
    .replace(/[ ]+/g, " ")
    .replace(/\n{2,}/g, "\n")
    .trim();
}

function chunkText(text, chunkSize = 900, overlap = 120) {
  const paragraphs = normalizeText(text)
    .split("\n")
    .map((x) => x.trim())
    .filter(Boolean);

  const chunks = [];
  let current = "";

  for (const para of paragraphs) {
    const candidate = current ? `${current}\n${para}` : para;

    if (candidate.length <= chunkSize) {
      current = candidate;
      continue;
    }

    if (current) {
      chunks.push(current);
    }

    if (para.length <= chunkSize) {
      current = para;
      continue;
    }

    let start = 0;
    while (start < para.length) {
      const end = start + chunkSize;
      chunks.push(para.slice(start, end));
      start += Math.max(1, chunkSize - overlap);
    }
    current = "";
  }

  if (current) {
    chunks.push(current);
  }

  return chunks;
}

async function loadKnowledgeBase() {
  const filePath = path.join(
    process.cwd(),
    "knowledge",
    "pickleball_chatbot_kb_chuan.docx"
  );

  if (!fs.existsSync(filePath)) {
    throw new Error(`Không tìm thấy knowledge base: ${filePath}`);
  }

  const result = await mammoth.extractRawText({ path: filePath });
  const rawText = normalizeText(result.value || "");
  const chunks = chunkText(rawText);

  kbState = {
    loaded: true,
    rawText,
    chunks,
    loadedAt: new Date(),
  };

  return kbState;
}

async function ensureLoaded() {
  if (kbState.loaded) return;
  try {
    await loadKnowledgeBase();
    return;
  } catch (_) {}
  const fallback = normalizeText(`Tây Mỗ Pickleball Club mở cửa từ 06:00 đến 22:00 mỗi ngày.
Khách có thể đặt sân trực tiếp trên ứng dụng ở mục Sản phẩm & dịch vụ hoặc Booking.
CLB có các sân pickleball, bóng, vợt và khu đồ ăn uống.
Giá sân thay đổi theo từng khung giờ, người dùng nên chọn khung giá khi đặt sân.
CLB có video hướng dẫn, voucher và vòng quay nhận thưởng mỗi ngày.
Người dùng có thể đăng ký lớp học pickleball với huấn luyện viên nếu hệ thống có mở lớp.
`);
  kbState = { loaded: true, rawText: fallback, chunks: chunkText(fallback), loadedAt: new Date() };
}

function tokenize(text) {
  return normalizeText(text)
    .toLowerCase()
    .split(/[^a-zA-Z0-9À-ỹ]+/)
    .filter(Boolean);
}

function scoreChunk(query, chunk) {
  const qWords = tokenize(query);
  const cText = normalizeText(chunk).toLowerCase();

  let score = 0;

  for (const word of qWords) {
    if (word.length <= 1) continue;
    if (cText.includes(word)) score += 1;
  }

  // boost theo intent phổ biến
  if (/giờ|mở cửa|đóng cửa/.test(query.toLowerCase()) && /6h|22h|giờ hoạt động/.test(cText)) {
    score += 4;
  }

  if (/giá|bao nhiêu|thuê sân/.test(query.toLowerCase()) && /230\.000|260\.000|300\.000|giờ thấp điểm|giờ cao điểm/.test(cText)) {
    score += 4;
  }

  if (/đặt sân|booking|book sân/.test(query.toLowerCase()) && /đặt sân|thanh toán|zalo|ứng dụng|app/.test(cText)) {
    score += 4;
  }

  return score;
}

async function searchKnowledgeBase(query, topK = 4) {
  await ensureLoaded();

  const ranked = kbState.chunks
    .map((chunk, index) => ({
      index,
      chunk,
      score: scoreChunk(query, chunk),
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, topK);

  return ranked.filter((x) => x.score > 0);
}

function getKbMeta() {
  return {
    loaded: kbState.loaded,
    loadedAt: kbState.loadedAt,
    chunkCount: kbState.chunks.length,
  };
}

module.exports = {
  loadKnowledgeBase,
  searchKnowledgeBase,
  getKbMeta,
};