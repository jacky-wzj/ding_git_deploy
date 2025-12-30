const crypto = require('crypto');
const config = require('./config');
const logger = require('./utils/logger');

/**
 * 验证钉钉签名
 * @param {string} timestamp - 时间戳
 * @param {string} sign - 签名
 * @returns {boolean}
 */
function verifySignature(timestamp, sign) {
  if (!config.dingtalk.secret) {
    logger.warn('钉钉密钥未配置，跳过签名验证');
    return true;
  }

  const stringToSign = `${timestamp}\n${config.dingtalk.secret}`;
  const hmac = crypto.createHmac('sha256', config.dingtalk.secret);
  const computedSign = hmac.update(stringToSign).digest('base64');
  
  return computedSign === sign;
}

/**
 * 发送文本消息到钉钉群
 * @param {string} content - 消息内容
 * @param {Array<string>} atMobiles - @的手机号列表
 * @param {boolean} isAtAll - 是否@所有人
 */
async function sendTextMessage(content, atMobiles = [], isAtAll = false) {
  if (!config.dingtalk.webhook) {
    logger.error('钉钉 Webhook 地址未配置');
    return;
  }

  const message = {
    msgtype: 'text',
    text: {
      content: content
    },
    at: {
      atMobiles: atMobiles,
      isAtAll: isAtAll
    }
  };

  try {
    const response = await fetch(config.dingtalk.webhook, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(message)
    });

    const result = await response.json();
    
    if (result.errcode === 0) {
      logger.info('钉钉消息发送成功');
    } else {
      logger.error(`钉钉消息发送失败: ${result.errmsg}`);
    }
  } catch (error) {
    logger.error(`发送钉钉消息异常: ${error.message}`);
  }
}

/**
 * 发送 Markdown 消息到钉钉群
 * @param {string} title - 消息标题
 * @param {string} text - Markdown 文本
 * @param {Array<string>} atMobiles - @的手机号列表
 * @param {boolean} isAtAll - 是否@所有人
 */
async function sendMarkdownMessage(title, text, atMobiles = [], isAtAll = false) {
  if (!config.dingtalk.webhook) {
    logger.error('钉钉 Webhook 地址未配置');
    return;
  }

  const message = {
    msgtype: 'markdown',
    markdown: {
      title: title,
      text: text
    },
    at: {
      atMobiles: atMobiles,
      isAtAll: isAtAll
    }
  };

  try {
    const response = await fetch(config.dingtalk.webhook, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(message)
    });

    const result = await response.json();
    
    if (result.errcode === 0) {
      logger.info('钉钉 Markdown 消息发送成功');
    } else {
      logger.error(`钉钉 Markdown 消息发送失败: ${result.errmsg}`);
    }
  } catch (error) {
    logger.error(`发送钉钉 Markdown 消息异常: ${error.message}`);
  }
}

module.exports = {
  verifySignature,
  sendTextMessage,
  sendMarkdownMessage
};

