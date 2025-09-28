; 定义 I2C 相关端口地址以及控制字等常量
I2C_SDA_PORT equ 288h ; I2C 数据线对应的 8255 端口地址
I2C_SCL_PORT equ 28ah ; I2C 时钟线对应的 8255 端口地址
I2C_CTRL_PORT equ 28bh ; 8255 控制端口地址
I2C_START_CTRL equ 82h ; 用于配置起始状态的控制字
I2C_IN_CTRL equ 8bh ; 用于配置输入相关状态的控制字
I2C_WRITE_CMD equ 0a0h ; 向设备写数据的命令
I2C_READ_CMD equ 0a1h ; 从设备读数据的命令
WRITE_REG_ADDR equ 45h ; 要写入数据的寄存器地址
READ_REG_ADDR equ 45h ; 要读取数据的寄存器地址
DATA_TO_WRITE equ 'a' ; 要发送的数据

code segment
assume cs:code
start:
;call init_8255 ; 初始化 8255 芯片相关端口配置
call write_data_to_device ; 向设备写入数据
call delay_long ; 进行较长时间延时
call read_data_from_device ; 从设备读取数据
jmp display_data ; 跳转到显示数据的循环部分
; 正确结束程序的部分
exit_program:
mov ah, 4ch
int 21h
; 向设备写入数据的过程
write_data_to_device proc near
call i2c_start ; 生成 I2C 总线起始信号
mov bl, I2C_WRITE_CMD
call send_byte ; 发送写命令字节
call wait_ack ; 等待应答
mov bl, WRITE_REG_ADDR
call send_byte ; 发送要写入的寄存器地址字节
call wait_ack ; 等待应答
mov bl, DATA_TO_WRITE ; 将要写入的数据放入 BL
call send_byte ; 发送数据字节
call wait_ack ; 等待应答

call i2c_stop ; 生成 I2C 总线停止信号
ret
write_data_to_device endp
; 从设备读取数据的过程
read_data_from_device proc near
call i2c_start ; 生成 I2C 总线起始信号
mov bl, I2C_WRITE_CMD
call send_byte ; 发送写命令
call wait_ack ; 等待应答
mov bl, READ_REG_ADDR
call send_byte ; 发送要读取的寄存器地址
call wait_ack ; 等待应答
call i2c_start ; 再次生成起始信号，切换到读模式
mov bl, I2C_READ_CMD
call send_byte ; 发送读命令字节
call wait_ack ; 等待应答
call read_byte ; 从总线上读取一个字节数据存到 BH
call send_nack ; 发送非应答信号
call i2c_stop ; 生成 I2C 总线停止信号
ret
read_data_from_device endp
; 配置8255 芯片端口配置为A口、C口输出
init_8255 proc near
push dx

push ax
mov dx, I2C_CTRL_PORT
mov al, I2C_START_CTRL
out dx, al
pop ax
pop dx
ret
init_8255 endp
; 配置8255 芯片端口配置为A口输出、C口输入
init_8255cin proc near
push dx
push ax
mov dx, I2C_CTRL_PORT
mov al, I2C_IN_CTRL
out dx, al
pop ax
pop dx
ret
init_8255cin endp
; 生成 I2C 总线起始信号的过程
i2c_start proc near
push dx
push ax
call init_8255
call set_sda_high
call set_scl_high

call set_sda_low
call set_scl_low
pop ax
pop dx
ret
i2c_start endp
; 生成 I2C 总线停止信号的过程
i2c_stop proc near
push dx
push ax
call init_8255
call set_sda_low
call set_scl_high
call set_sda_high
pop ax
pop dx
ret
i2c_stop endp
; 按位发送字节数据的过程
send_byte proc near
push cx
push dx
push ax
mov cl, 8
CALL init_8255
mov dx, I2C_SCL_PORT

wr_loop:
rol bl, 1 ; BL 存放待输出数据，循环左移取每一位发送
mov al, bl
and al, 01h
out dx, al
call delay_short
call set_scl_high
call set_scl_low
dec cl
jnz wr_loop
pop ax
pop dx
pop cx
ret
send_byte endp
; 按位接收字节数据的过程
read_byte proc near
push cx
push dx
push ax
mov cl, 8
mov bh, 00h
CALL init_8255
call set_sda_high
CALL init_8255cin
mov dx, I2C_SCL_PORT
re_loop:

call set_scl_high
in al, dx
and al, 01h
shl bh, 1 ; BH 存放接收数据，逐位组合
or bh, al
call set_scl_low
dec cl
jnz re_loop
pop ax
pop dx
pop cx
ret
read_byte endp
; 等待应答信号的过程
wait_ack proc near
push dx
push ax
call init_8255
call set_sda_high
CALL init_8255cin
mov dx, I2C_SCL_PORT
call set_scl_high
in al, dx ; 读取应答位数据存到 BL
mov bl, al
call set_scl_low
pop ax
pop dx

ret
wait_ack endp
; 发送非应答信号的过程
send_nack proc near
push dx
push ax
call init_8255
mov dx, I2C_SCL_PORT
mov al, 01h
out dx, al
call delay_short
call set_scl_high
call set_scl_low
pop ax
pop dx
ret
send_nack endp
; 拉高 SDA 数据线的过程
set_sda_high proc near
push dx
push ax
mov dx, I2C_SCL_PORT
mov al, 01h
out dx, al
call delay_short

pop ax
pop dx
ret
set_sda_high endp
; 拉低 SDA 数据线的过程
set_sda_low proc near
push dx
push ax
mov dx, I2C_SCL_PORT
mov al, 00h
out dx, al
call delay_short
pop ax
pop dx
ret
set_sda_low endp
; 拉高 SCL 时钟线的过程
set_scl_high proc near
push dx
push ax
mov dx, I2C_SDA_PORT
mov al, 1
out dx, al
call delay_short
pop ax
pop dx

ret
set_scl_high endp
; 拉低 SCL 时钟线的过程
set_scl_low proc near
push dx
push ax
mov dx, I2C_SDA_PORT
mov al, 0
out dx, al
call delay_short
pop ax
pop dx
ret
set_scl_low endp
; 短暂延时的过程，用于满足 I2C 信号时序等基本要求
delay_short proc near
push bx
push cx
mov bx, 128
delay_short_loop:
mov cx, 0
delay_short_inner_loop:
loop delay_short_inner_loop
dec bx
jne delay_short_loop
pop cx

pop bx
ret
delay_short endp
; 较长时间延时的过程
delay_long proc near
push bx
push cx
mov bx, 1024
delay_long_loop:
mov cx, 0
delay_long_inner_loop:
loop delay_long_inner_loop
dec bx
jne delay_long_loop
pop cx
pop bx
ret
delay_long endp
; 显示读取到的数据的循环
display_data:
mov ah, 0bh ; 获取键盘输入状态功能号
int 21h
cmp al, 0ffh ; 判断是否有按键按下
je exit_program ; 如果有按键按下，跳转到结束程序部分
mov al, bh
mov ah, 0eh

int 10h
call delay_short
jmp display_data
code ends
end start
