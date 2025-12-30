require('dotenv').config();

module.exports = {
  // 服务配置
  port: process.env.PORT || 3000,
  
  // 钉钉配置
  dingtalk: {
    secret: process.env.DINGTALK_SECRET,
    webhook: process.env.DINGTALK_WEBHOOK
  },
  
  // 项目配置
  project: {
    path: process.env.PROJECT_PATH,
    gitBranch: process.env.GIT_BRANCH || 'main'
  },
  
  // Nginx 配置
  nginx: {
    path: process.env.NGINX_PATH || 'nginx'
  },
  
  // 部署命令配置
  commands: {
    gitPull: (branch) => `git pull origin ${branch}`,
    pnpmInstall: 'pnpm install --prod=false',
    pnpmBuild: 'pnpm build',
    nginxReload: (nginxPath) => `${nginxPath} -s reload`
  }
};

