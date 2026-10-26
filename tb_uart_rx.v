`timescale 1ns / 1ps

module tb_uart_rx;
    reg clk = 0;
    reg rst = 1;
    reg rx = 1;
    wire [7:0] data;
    wire valid;
    wire error;

    // Khởi tạo module bộ thu UART (dùng N = 16 cho nhanh)
    uart_rx #(.N(16)) uut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .data(data),
        .valid(valid),
        .error(error)
    );

    // Tạo xung clock 10ns (5ns high, 5ns low)
    always #5 clk = ~clk;

    // Task truyền 1 bit
    task send_bit;
        input b;
        begin
            @(negedge clk);
            rx = b;
            repeat (16) @(negedge clk);
        end
    endtask

    // Task truyền 1 byte (8N1)
    task send_byte;
        input [7:0] value;
        input stop_bit;
        integer i;
        begin
            send_bit(0); // Start bit
            for (i = 0; i < 8; i = i + 1) begin
                send_bit(value[i]); // Data bits (LSB first)
            end
            send_bit(stop_bit); // Stop bit
            send_bit(1); // Trở về mức rỗi (Idle)
        end
    endtask

    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, tb_uart_rx);

        repeat (3) @(negedge clk);
        rst = 0; // Thả reset

        // Test 1: Gửi byte 0xA5 với stop bit đúng (1)
        send_byte(8'hA5, 1);

        // Test 2: Gửi byte 0x3C với stop bit sai (0) để kiểm tra lỗi khung
        send_byte(8'h3C, 0);

        repeat (20) @(negedge clk);
        $finish;
    end

    // Theo dõi kết quả xuất ra màn hình
    always @(posedge clk) begin
        if (valid) $display("Nhan thanh cong: %h", data);
        if (error) $display("LOI KHUNG (Frame Error)");
    end

endmodule
