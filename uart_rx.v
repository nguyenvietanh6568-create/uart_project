module uart_rx (
    input clk,
    input rst,
    input rx,
    output reg [7:0] data,
    output reg valid,
    output reg error
);
    parameter N = 16;
    reg [1:0] state;
    reg [15:0] count;
    reg [2:0] bit_index;
    reg [7:0] temp;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            count <= 0;
            bit_index <= 0;
            temp <= 0;
            data <= 0;
            valid <= 0;
            error <= 0;
        end else begin
            valid <= 0;
            error <= 0;
            case (state)
                // 0: Chờ start bit (rx xuống 0)
                0: begin
                    count <= 0;
                    if (rx == 0) state <= 1;
                end
                // 1: Chờ nửa bit để xác nhận start bit
                1: begin
                    if (count == N / 2 - 1) begin
                        count <= 0;
                        if (rx == 0) state <= 2;
                        else state <= 0;
                    end else begin
                        count <= count + 1;
                    end
                end
                // 2: Nhận 8 bit dữ liệu (LSB trước)
                2: begin
                    if (count == N - 1) begin
                        count <= 0;
                        temp[bit_index] <= rx;
                        if (bit_index == 7) begin
                            bit_index <= 0;
                            state <= 3;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else begin
                        count <= count + 1;
                    end
                end
                // 3: Kiểm tra stop bit
                3: begin
                    if (count == N - 1) begin
                        count <= 0;
                        state <= 0;
                        if (rx == 1) begin
                            data <= temp;
                            valid <= 1;
                        end else begin
                            error <= 1;
                        end
                    end else begin
                        count <= count + 1;
                    end
                end
                default: state <= 0;
            endcase
        end
    end
endmodule
