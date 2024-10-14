module gen_irq (
  input wire              [11:0] vec,
  input wire               [7:0] fnc,
  input wire                     trig,

  output wire                    recv,
  output wire                    ack,
  output wire                    fail,

  output wire             [11:0] usr_irq_in_vec,
  output wire              [7:0] usr_irq_in_fnc,
  output wire                    usr_irq_in_vld,
  input wire                     usr_irq_out_ack,
  input wire                     usr_irq_out_fail,

  input wire                     clk,
  input wire                     rstn
);

reg        reg_recv;
reg        reg_ack;
reg  [3:0] reg_timeout;
reg        reg_fail;
reg [11:0] reg_usr_irq_in_vec;
reg  [7:0] reg_usr_irq_in_fnc;
reg        reg_usr_irq_in_vld;

assign recv = reg_recv;
assign ack = reg_ack;
assign fail = reg_fail;
assign usr_irq_in_vec = reg_usr_irq_in_vec;
assign usr_irq_in_fnc = reg_usr_irq_in_fnc;
assign usr_irq_in_vld = reg_usr_irq_in_vld;


localparam IDLE     = 1'b0;
localparam WAIT_ACK = 1'b1;

reg  [1:0] state, next_state;

always @(posedge clk) begin
    if (~rstn) begin
        reg_usr_irq_in_vec <= 12'b0;
        reg_usr_irq_in_fnc <= 8'b0;
        reg_usr_irq_in_vld <= 1'b0;
        reg_recv <= 1'b0;
        reg_ack <= 1'b0;
        reg_timeout <= 0;
        reg_fail <= 1'b0;
        next_state <= IDLE;
        state <= IDLE;
    end else begin
        case (state)
            IDLE: begin
                if (trig) begin
                    reg_recv <= 1'b1;
                    reg_ack <= 1'b0;
                    reg_fail <= 1'b0;
                    reg_usr_irq_in_fnc <= fnc;
                    reg_usr_irq_in_vec <= vec;
                    reg_usr_irq_in_vld <= 1'b1;
                    next_state <= WAIT_ACK;
                end else begin
                    next_state <= IDLE;
                end
            end
            WAIT_ACK: begin
                if (usr_irq_out_ack || reg_timeout > 9) begin // workaround for missing ack
                    reg_timeout <= 0;
                    reg_ack <= 1'b1;
                    reg_recv <= 1'b0;
                    reg_usr_irq_in_vld <= 1'b0;
                    next_state <= IDLE;
                end else if (usr_irq_out_fail) begin
                    reg_timeout <= 0;
                    reg_fail <= 1'b1; 
                    reg_recv <= 1'b0;  
                    reg_usr_irq_in_vld <= 1'b0;               
                    next_state <= IDLE;
                end
                reg_timeout <= reg_timeout + 1;
            end
        endcase
        state = next_state;
    end
end

endmodule