const express = require('express');
const config = require('./config');
const logger = require('./utils/logger');
const { verifySignature } = require('./dingtalk');
const { deploy } = require('./deploy');

const app = express();

// 解析 JSON 请求体
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 健康检查接口
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// 钉钉 Webhook 回调接口
app.post('/webhook/dingtalk', async (req, res) => {
  try {
    const timestamp = req.headers['timestamp'];
    const sign = req.headers['sign'];
    const body = req.body;

    logger.info('收到钉钉 webhook 回调');
    logger.debug(`请求体: ${JSON.stringify(body)}`);

    // 验证签名
    if (config.dingtalk.secret) {
      if (!verifySignature(timestamp, sign)) {
        logger.warn('签名验证失败');
        return res.status(401).json({ error: '签名验证失败' });
      }
    }

    // 快速响应钉钉服务器（避免超时）
    res.json({ success: true });

    // 检查是否是 @机器人 的消息
    const msgtype = body.msgtype;
    
    if (msgtype === 'text') {
      const atUserIds = body.text?.atUserIds || [];
      const content = body.text?.content || '';
      const senderNick = body.senderNick || '未知用户';
      
      logger.info(`收到消息: ${content} (发送人: ${senderNick})`);
      
      // 检查是否 @ 了机器人
      // 注意: atUserIds 为空数组时，可能是群消息但没有@任何人
      // 如果钉钉机器人设置了"@才能触发"，这里会有机器人ID
      
      // 这里我们简化处理：只要收到消息就触发部署
      // 你可以根据实际需求添加更多判断条件，比如检查消息内容包含特定关键字
      
      logger.info(`触发部署流程 (触发人: ${senderNick})`);
      
      // 异步执行部署，不阻塞响应
      deploy(senderNick).catch(error => {
        logger.error(`部署流程异常: ${error.message}`);
      });
    }

  } catch (error) {
    logger.error(`处理 webhook 异常: ${error.message}`);
    // 已经响应过了，这里不再响应
  }
});

// 手动触发部署接口（用于测试）
app.post('/deploy', async (req, res) => {
  try {
    logger.info('收到手动部署请求');
    
    // 异步执行部署
    deploy('手动触发').catch(error => {
      logger.error(`部署流程异常: ${error.message}`);
    });
    
    res.json({ 
      success: true, 
      message: '部署已开始，请在钉钉群查看进度' 
    });
  } catch (error) {
    logger.error(`手动部署异常: ${error.message}`);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// 404 处理
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

// 错误处理
app.use((err, req, res, next) => {
  logger.error(`服务器错误: ${err.message}`);
  res.status(500).json({ error: 'Internal Server Error' });
});

// 启动服务
const PORT = config.port;
app.listen(PORT, () => {
  logger.info(`========================================`);
  logger.info(`钉钉部署机器人服务已启动`);
  logger.info(`端口: ${PORT}`);
  logger.info(`环境: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`项目路径: ${config.project.path}`);
  logger.info(`========================================`);
});

// 优雅退出
process.on('SIGINT', () => {
  logger.info('收到 SIGINT 信号，正在关闭服务...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  logger.info('收到 SIGTERM 信号，正在关闭服务...');
  process.exit(0);
});

// 未捕获的异常
process.on('uncaughtException', (error) => {
  logger.error(`未捕获的异常: ${error.message}`);
  logger.error(error.stack);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error(`未处理的 Promise 拒绝: ${reason}`);
});

