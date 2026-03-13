const OpenAI = require('openai');
const { detectIntent } = require('./chatbot.intent.service');
const { searchKnowledgeBase } = require('./chatbot.kb.service');
const { getLiveContext, formatLiveContext } = require('./chatbot.live.service');

const client = process.env.OPENAI_API_KEY
  ? new OpenAI({ apiKey: process.env.OPENAI_API_KEY })
  : null;

async function buildKbContext(question) {
  const results = await searchKnowledgeBase(question, 4);
  return results.map((r, i) => `[KB ${i + 1}]\n${r.chunk}`).join('\n\n');
}

async function buildContext({ question, userId }) {
  const intent = detectIntent(question);
  let kbContext = '';
  let liveContext = '';

  if (['KB_ONLY', 'HYBRID_COURT', 'HYBRID_GENERAL'].includes(intent)) {
    kbContext = await buildKbContext(question);
  }

  if (
    [
      'LIVE_VOUCHER',
      'LIVE_VIDEO',
      'LIVE_COACH',
      'LIVE_MY_BOOKING',
      'HYBRID_COURT',
      'HYBRID_GENERAL',
    ].includes(intent)
  ) {
    const liveData = await getLiveContext({ question, userId });
    liveContext = formatLiveContext(liveData);
  }

  return { intent, kbContext, liveContext };
}

function localAnswer(question, kbContext, liveContext) {
  const q = String(question || '').toLowerCase();
  if (/gio|giờ|mở cửa|đóng cửa/.test(q)) {
    return 'CLB hiện mở cửa từ 06:00 đến 22:00 mỗi ngày.';
  }
  if (/đặt sân|book sân|booking/.test(q)) {
    return `Bạn có thể vào mục Sản phẩm & dịch vụ, chọn tab Sân, chọn khung giờ phù hợp rồi xác nhận đặt sân.${
      liveContext ? `\n\nThông tin hiện có:\n${liveContext}` : ''
    }`;
  }
  if (/voucher|ưu đãi/.test(q)) return liveContext || 'Hiện chưa có dữ liệu voucher hoạt động.';
  if (/video/.test(q)) return liveContext || 'Hiện chưa có video phù hợp.';
  if (/huấn luyện viên|coach|lớp học/.test(q)) return liveContext || kbContext || 'Hiện chưa có thông tin lớp học hoặc huấn luyện viên phù hợp.';
  return (liveContext || kbContext || 'Mình chưa có đủ dữ liệu để trả lời câu hỏi này.').slice(0, 1200);
}

async function askChatbot({ question, userId }) {
  const { intent, kbContext, liveContext } = await buildContext({ question, userId });

  if (!client) {
    return {
      question,
      answer: localAnswer(question, kbContext, liveContext),
      userId,
      meta: {
        intent,
        usedKb: Boolean(kbContext),
        usedLive: Boolean(liveContext),
        provider: 'local',
      },
    };
  }

  const systemPrompt = [
    'Bạn là chatbot chăm sóc khách hàng cho Pickleball Tây Mỗ Club.',
    'Trả lời bằng tiếng Việt, ngắn gọn, thân thiện.',
    'Ưu tiên dữ liệu LIVE nếu có.',
    'Nếu dữ liệu không có, nói rõ hệ thống chưa có thông tin đó.',
  ].join('\n');

  const userPrompt = [
    'CÂU HỎI:',
    question,
    '',
    'INTENT:',
    intent,
    '',
    'KNOWLEDGE BASE:',
    kbContext || 'Không có',
    '',
    'LIVE DATA:',
    liveContext || 'Không có',
    '',
    'Hãy trả lời ngắn gọn nhưng hữu ích.',
  ].join('\n');

  try {
    const response = await client.responses.create({
      model: process.env.OPENAI_CHAT_MODEL || 'gpt-4.1-mini',
      input: [
        { role: 'system', content: [{ type: 'input_text', text: systemPrompt }] },
        { role: 'user', content: [{ type: 'input_text', text: userPrompt }] },
      ],
    });

    return {
      question,
      answer: response.output_text || localAnswer(question, kbContext, liveContext),
      userId,
      meta: {
        intent,
        usedKb: Boolean(kbContext),
        usedLive: Boolean(liveContext),
        provider: 'openai',
      },
    };
  } catch (error) {
    return {
      question,
      answer: localAnswer(question, kbContext, liveContext),
      userId,
      meta: {
        intent,
        usedKb: Boolean(kbContext),
        usedLive: Boolean(liveContext),
        provider: 'fallback',
        error: error.message,
      },
    };
  }
}

module.exports = { askChatbot };
