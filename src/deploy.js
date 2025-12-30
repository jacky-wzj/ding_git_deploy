const { exec } = require('child_process');
const { promisify } = require('util');
const config = require('./config');
const logger = require('./utils/logger');
const { sendMarkdownMessage } = require('./dingtalk');

const execPromise = promisify(exec);

/**
 * 执行 shell 命令
 * @param {string} command - 要执行的命令
 * @param {string} cwd - 工作目录
 * @returns {Promise<{stdout: string, stderr: string}>}
 */
async function executeCommand(command, cwd) {
  logger.info(`执行命令: ${command} (目录: ${cwd})`);
  
  try {
    const { stdout, stderr } = await execPromise(command, {
      cwd: cwd,
      maxBuffer: 1024 * 1024 * 10, // 10MB
      timeout: 5 * 60 * 1000 // 5分钟超时
    });
    
    if (stdout) {
      logger.info(`命令输出: ${stdout.trim()}`);
    }
    
    if (stderr) {
      logger.warn(`命令错误输出: ${stderr.trim()}`);
    }
    
    return { stdout, stderr, success: true };
  } catch (error) {
    logger.error(`命令执行失败: ${error.message}`);
    return { 
      stdout: error.stdout || '', 
      stderr: error.stderr || error.message, 
      success: false,
      error: error.message
    };
  }
}

/**
 * 格式化执行时间
 * @param {number} ms - 毫秒数
 * @returns {string}
 */
function formatDuration(ms) {
  const seconds = Math.floor(ms / 1000);
  if (seconds < 60) {
    return `${seconds}秒`;
  }
  const minutes = Math.floor(seconds / 60);
  const remainSeconds = seconds % 60;
  return `${minutes}分${remainSeconds}秒`;
}

/**
 * 获取当前 Git 分支名
 * @param {string} cwd - 工作目录
 * @returns {Promise<string>} 分支名
 */
async function getCurrentBranch(cwd) {
  try {
    const { stdout } = await execPromise('git rev-parse --abbrev-ref HEAD', { cwd });
    return stdout.trim();
  } catch (error) {
    logger.warn(`获取当前分支失败: ${error.message}`);
    return null;
  }
}

/**
 * 检查远程分支是否存在
 * @param {string} branch - 分支名
 * @param {string} cwd - 工作目录
 * @returns {Promise<boolean>}
 */
async function checkRemoteBranchExists(branch, cwd) {
  try {
    // 先 fetch 更新远程分支信息
    await execPromise('git fetch origin', { cwd, timeout: 30000 });
    
    // 检查远程分支是否存在
    const { stdout } = await execPromise(`git ls-remote --heads origin ${branch}`, { cwd });
    return stdout.trim().length > 0;
  } catch (error) {
    logger.warn(`检查远程分支失败: ${error.message}`);
    return false;
  }
}

/**
 * 智能 Git Pull
 * @param {string} branch - 目标分支
 * @param {string} cwd - 工作目录
 * @returns {Promise<{stdout: string, stderr: string, success: boolean, actualBranch: string}>}
 */
async function smartGitPull(branch, cwd) {
  let actualBranch = branch;
  
  // 先检查远程分支是否存在
  const remoteBranchExists = await checkRemoteBranchExists(branch, cwd);
  
  if (!remoteBranchExists) {
    // 如果远程分支不存在，尝试使用当前分支
    const currentBranch = await getCurrentBranch(cwd);
    if (currentBranch && currentBranch !== branch) {
      logger.warn(`远程分支 ${branch} 不存在，使用当前分支 ${currentBranch}`);
      actualBranch = currentBranch;
    } else {
      // 尝试常见分支名
      const commonBranches = ['master', 'develop', 'dev'];
      for (const commonBranch of commonBranches) {
        if (await checkRemoteBranchExists(commonBranch, cwd)) {
          logger.warn(`远程分支 ${branch} 不存在，使用分支 ${commonBranch}`);
          actualBranch = commonBranch;
          break;
        }
      }
    }
  }
  
  // 执行 git pull
  const result = await executeCommand(`git pull origin ${actualBranch}`, cwd);
  return {
    ...result,
    actualBranch
  };
}

/**
 * 执行部署流程
 * @param {string} senderName - 触发部署的用户名
 */
async function deploy(senderName = '未知用户') {
  const startTime = Date.now();
  const projectPath = config.project.path;
  const gitBranch = config.project.gitBranch;
  
  logger.info(`========== 开始部署流程 (触发人: ${senderName}) ==========`);
  
  // 发送开始消息
  await sendMarkdownMessage(
    '🚀 开始部署',
    `### 🚀 部署开始\n\n` +
    `**触发人**: ${senderName}\n\n` +
    `**时间**: ${new Date().toLocaleString('zh-CN')}\n\n` +
    `**项目路径**: ${projectPath}\n\n` +
    `**分支**: ${gitBranch}\n\n` +
    `---\n\n` +
    `⏳ 正在执行部署流程，请稍候...`
  );

  const results = [];
  let hasError = false;
  let actualBranch = gitBranch;

  // 步骤1: Git Pull
  logger.info('步骤 1/4: 拉取最新代码');
  const gitResult = await smartGitPull(gitBranch, projectPath);
  
  // 如果使用了不同的分支，更新实际使用的分支名
  if (gitResult.actualBranch && gitResult.actualBranch !== gitBranch) {
    actualBranch = gitResult.actualBranch;
    logger.info(`实际使用的分支: ${actualBranch}`);
  }
  
  results.push({
    step: 1,
    name: '拉取代码',
    command: `git pull origin ${actualBranch}`,
    ...gitResult
  });
  
  if (!gitResult.success) {
    hasError = true;
  }

  // 步骤2: pnpm install (只有在前一步成功时才执行)
  if (!hasError) {
    logger.info('步骤 2/4: 安装依赖');
    const installResult = await executeCommand(
      config.commands.pnpmInstall,
      projectPath
    );
    results.push({
      step: 2,
      name: '安装依赖',
      command: config.commands.pnpmInstall,
      ...installResult
    });
    
    if (!installResult.success) {
      hasError = true;
    }
  }

  // 步骤3: pnpm build
  if (!hasError) {
    logger.info('步骤 3/4: 构建项目');
    const buildResult = await executeCommand(
      config.commands.pnpmBuild,
      projectPath
    );
    results.push({
      step: 3,
      name: '构建项目',
      command: config.commands.pnpmBuild,
      ...buildResult
    });
    
    if (!buildResult.success) {
      hasError = true;
    }
  }

  // 步骤4: Nginx Reload
  if (!hasError) {
    logger.info('步骤 4/4: 重载 Nginx');
    const nginxResult = await executeCommand(
      config.commands.nginxReload(config.nginx.path),
      projectPath
    );
    results.push({
      step: 4,
      name: '重载 Nginx',
      command: config.commands.nginxReload(config.nginx.path),
      ...nginxResult
    });
    
    if (!nginxResult.success) {
      hasError = true;
    }
  }

  const endTime = Date.now();
  const duration = endTime - startTime;

  logger.info(`========== 部署流程结束 (耗时: ${formatDuration(duration)}) ==========`);

  // 构建结果消息
  let resultMessage = hasError ? '### ❌ 部署失败\n\n' : '### ✅ 部署成功\n\n';
  resultMessage += `**触发人**: ${senderName}\n\n`;
  resultMessage += `**时间**: ${new Date().toLocaleString('zh-CN')}\n\n`;
  resultMessage += `**项目路径**: ${projectPath}\n\n`;
  resultMessage += `**分支**: ${actualBranch}${actualBranch !== gitBranch ? ` (配置: ${gitBranch})` : ''}\n\n`;
  resultMessage += `**耗时**: ${formatDuration(duration)}\n\n`;
  resultMessage += `---\n\n`;
  resultMessage += `#### 执行详情\n\n`;

  results.forEach(result => {
    const icon = result.success ? '✅' : '❌';
    resultMessage += `${icon} **步骤 ${result.step}: ${result.name}**\n\n`;
    resultMessage += `\`\`\`\n${result.command}\n\`\`\`\n\n`;
    
    if (!result.success) {
      resultMessage += `> ❌ 错误信息:\n`;
      resultMessage += `> ${result.stderr || result.error}\n\n`;
    } else if (result.stdout) {
      const output = result.stdout.trim().substring(0, 200);
      resultMessage += `> ${output}${result.stdout.length > 200 ? '...' : ''}\n\n`;
    }
  });

  if (hasError) {
    resultMessage += `---\n\n`;
    resultMessage += `⚠️ **提示**: 部署失败，请检查错误信息并手动处理。\n\n`;
    resultMessage += `可能需要登录服务器手动排查问题。`;
  } else {
    resultMessage += `---\n\n`;
    resultMessage += `🎉 **部署已完成，新版本已生效！**`;
  }

  // 发送结果消息
  await sendMarkdownMessage(
    hasError ? '❌ 部署失败' : '✅ 部署成功',
    resultMessage
  );

  return {
    success: !hasError,
    results,
    duration
  };
}

module.exports = {
  deploy
};

