# AlphaGenome Proxy - 快速部署指南

## 🚀 一键部署

### 1. 环境准备
确保您的系统已安装：
- Docker
- Docker Compose
- Git

### 2. 配置API密钥
```bash
# 复制环境配置文件
cp env.example .env

# 编辑配置文件，设置您的AlphaGenome API密钥
nano .env
```

在`.env`文件中设置：
```bash
ALPHAGENOME_API_KEY=your_real_alphagenome_api_key_here
```

### 3. 快速部署
```bash
# 使用增强版部署脚本
./cloud-deploy.sh
```

或者使用基础部署脚本：
```bash
./deploy.sh
```

### 4. 验证部署
```bash
# 检查服务状态
./monitor.sh

# 或者手动检查
curl http://localhost/health
curl http://localhost/api/docs
```

## 📋 服务访问地址

部署成功后，您可以通过以下地址访问服务：

- **Web界面**: http://localhost
- **API服务**: http://localhost/api
- **API文档**: http://localhost/api/docs
- **健康检查**: http://localhost/health

## 🔧 常用命令

### 服务管理
```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f

# 查看服务状态
docker-compose ps
```

### 监控和维护
```bash
# 运行监控脚本
./monitor.sh

# 清理Docker资源
docker system prune -f

# 更新服务
docker-compose pull && docker-compose up -d
```

## 🏭 生产环境部署

### 使用生产配置
```bash
# 使用生产环境配置
docker-compose -f docker-compose.prod.yml up -d
```

### SSL证书配置
1. 将SSL证书文件放在`ssl/`目录下
2. 取消注释`docker-compose.prod.yml`中的SSL配置
3. 重启服务

### 域名配置
1. 修改`nginx.conf`中的`server_name`
2. 配置DNS解析
3. 重启Nginx服务

## 🐛 故障排除

### 常见问题

1. **服务启动失败**
   ```bash
   # 检查日志
   docker-compose logs
   
   # 检查环境变量
   cat .env
   ```

2. **API密钥错误**
   ```bash
   # 验证API密钥
   curl -H "Authorization: Bearer your_api_key" \
        http://localhost/api/health
   ```

3. **端口冲突**
   ```bash
   # 检查端口占用
   netstat -tulpn | grep :80
   netstat -tulpn | grep :8000
   ```

4. **资源不足**
   ```bash
   # 检查系统资源
   docker stats
   free -h
   df -h
   ```

### 重置部署
```bash
# 完全重置
docker-compose down -v
docker system prune -f
./cloud-deploy.sh
```

## 📊 性能优化

### 资源限制
生产环境建议配置：
- CPU: 1-2 cores
- 内存: 2-4GB
- 磁盘: 20GB+

### 监控建议
- 定期运行`./monitor.sh`
- 设置日志轮转
- 配置告警机制

## 🔒 安全建议

1. **API密钥安全**
   - 不要在代码中硬编码API密钥
   - 定期轮换API密钥
   - 使用环境变量管理密钥

2. **网络安全**
   - 配置防火墙规则
   - 使用HTTPS
   - 限制访问IP

3. **容器安全**
   - 定期更新基础镜像
   - 使用非root用户运行
   - 扫描安全漏洞

## 📞 支持

如果遇到问题，请检查：
1. Docker和Docker Compose版本
2. 系统资源是否充足
3. 网络连接是否正常
4. API密钥是否有效

更多详细信息请参考：
- `DOCKER_DEPLOYMENT_GUIDE.md`
- `DEPLOYMENT_SUMMARY.md`
