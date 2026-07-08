(function(){
  var l = (navigator.language || navigator.userLanguage || "en").toLowerCase();
  var z = l.indexOf("zh") > -1;
  document.documentElement.lang = z ? "zh-CN" : "en";
  var m = document.createElement("meta");
  m.name = "description";
  m.content = z
    ? "EnlyAI是统一的AI大模型API网关，一个API Key即可调用GPT-5、Claude、Gemini、DeepSeek等所有主流大模型。支持OpenAI兼容格式，免费额度，无需信用卡，国内快速访问。"
    : "EnlyAI is a unified LLM API gateway. One API key to access GPT-5, Claude, Gemini, DeepSeek and all major AI models. OpenAI-compatible, free tier, no credit card required.";
  document.head.appendChild(m);
  var k = document.createElement("meta");
  k.name = "keywords";
  k.content = z
    ? "AI API,大模型API,GPT-5 API,Claude API,Gemini API,DeepSeek API,免费API,OpenAI兼容,API网关,聚合API"
    : "AI API,LLM API,GPT-5 API,Claude API,Gemini API,DeepSeek API,free API,OpenAI compatible,API gateway";
  document.head.appendChild(k);
})();