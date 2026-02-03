#!/bin/bash

# 检查root权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "错误：此脚本需要root权限执行。请使用sudo运行！"
        exit 1
    fi
}

# 创建用户函数
create_user() {
    read -p "请输入用户名: " username
    if id "$username" &>/dev/null; then
        echo "错误：用户 '$username' 已存在！"
        return
    fi

    read -s -p "请输入密码: " password
    echo
    read -s -p "确认密码: " password_confirm
    echo

    if [ "$password" != "$password_confirm" ]; then
        echo "错误：两次输入的密码不匹配！"
        return
    fi

    # 创建用户
    useradd -m -s /bin/bash "$username" &>/dev/null
    if [ $? -ne 0 ]; then
        echo "错误：创建用户失败！"
        return
    fi

    # 设置密码
    echo "$username:$password" | chpasswd
    echo "用户 '$username' 创建成功！"
}

# 创建管理员用户
create_admin() {
    create_user
    if ! id "$username" &>/dev/null; then return; fi

    # 添加到sudo组（兼容不同发行版）
    if grep -q '^sudo:' /etc/group; then
        usermod -aG sudo "$username"
    elif grep -q '^wheel:' /etc/group; then
        usermod -aG wheel "$username"
    else
        echo "警告：未找到sudo或wheel组，已创建为普通用户。"
        return
    fi

    echo "管理员用户 '$username' 创建成功！"
}

# 修改密码
change_password() {
    read -p "请输入用户名: " username
    if ! id "$username" &>/dev/null; then
        echo "错误：用户 '$username' 不存在！"
        return
    fi

    read -s -p "请输入新密码: " password
    echo
    read -s -p "确认新密码: " password_confirm
    echo

    if [ "$password" != "$password_confirm" ]; then
        echo "错误：两次输入的密码不匹配！"
        return
    fi

    echo "$username:$password" | chpasswd
    echo "用户 '$username' 的密码已更新！"
}

# 列举所有普通用户
list_users() {
    echo "系统用户列表 (UID >= 1000):"
    echo "-------------------------"
    awk -F: '$3 >= 1000 && $3 < 60000 {print "用户名:", $1, " UID:", $3}' /etc/passwd
}

# 删除用户
delete_user() {
    read -p "请输入要删除的用户名: " username
    if ! id "$username" &>/dev/null; then
        echo "错误：用户 '$username' 不存在！"
        return
    fi

    read -p "是否删除用户主目录？(y/n): " del_home
    if [ "$del_home" = "y" ]; then
        userdel -r "$username"
    else
        userdel "$username"
    fi

    # 检查删除结果
    if [ $? -eq 0 ]; then
        echo "用户 '$username' 已成功删除！"
    else
        echo "错误：删除用户失败！"
    fi
}
