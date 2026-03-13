const service = require("./chatbot.service");
const { successResponse, errorResponse } = require("../utils/response");

const askChatbot = async (req, res) => {
  try {
    const question = req.body.question?.trim();

    if (!question) {
      return errorResponse(res, "Thiếu câu hỏi", 400);
    }

    const data = await service.askChatbot({
      question,
      userId: req.user?.id || null,
    });

    return successResponse(res, data, "Chatbot answered");
  } catch (error) {
    console.error("chatbot ask error:", error);
    return errorResponse(res, error.message || "Chatbot error", 400);
  }
};

module.exports = { askChatbot };