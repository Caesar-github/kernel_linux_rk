# 内核帮助文档

## 内核编译

方法一：调用鸿蒙OS的build.sh脚本编译：

```
./build.sh --product-name rk3566 --build-target kernel
```

方法二：单独编译内核

```
cd kernel/linux-4.19
export PRODUCT_PATH=vendor/rockchip/rk3566
./make-ohos.sh rk356x
cp boot_linux.img out/ohos-arm-release/packages/phone/images/
```

## 添加开发板加入到支持列表

1. 确保新的开发板，所有同型号开发板的SN的前6位是一致的，假设为：ABCDEF

2. 在arch/arm64/boot/dts/rockchip/下创建开发板对应的内核设备树文件，假设为：rk3568-xxxx.dts

3. 修改make-ohos.sh如下：（假设次开发板的型号是：TB-NEW-V11）

   ```
   #model                   flag(the top six of SN)  dts                           multi
   product_TB_RK3568C1_C="  TC031C                   rk3568-toybrick-core-linux    1"
   product_TB_RK3568X0="    TX0356                   rk3568-toybrick-core-linux-x0 0"
   product_TB_RK3568Xs0="   TXs356                   rk3568-toybrick-core-linux    1"
   product_TB_RK3568X1_C="  TX031C                   rk3568-toybrick-core-linux-x0 0"
   product_TB_RK3568X0_C="  TX030C                   rk3568-toybrick-core-linux-x0 0"
   product_RK3566_EVB2_V11="TE2011                   rk3566-evb2-lp4x-v10-linux    0"
   product_RK3568_EVB1_V10="TE1110                   rk3568-evb1-ddr4-v10-linux    0"
   product_TB_NEW_V11="     ABCDEF                   rk3568-xxxx                   0"   <---- 添加代码
   
   product_rk356x=(
   	"${product_TB_RK3568C1_C}"
   	"${product_TB_RK3568X0}"
   	"${product_TB_RK3568Xs0}"
   	"${product_TB_RK3568X1_C}"
   	"${product_TB_RK3568X0_C}"
   	"${product_RK3566_EVB2_V11}"
   	"${product_RK3568_EVB1_V10}"
   	"${product_TB_NEW_V11}"                                                           <--- 添加代码
   	)
   ```

   