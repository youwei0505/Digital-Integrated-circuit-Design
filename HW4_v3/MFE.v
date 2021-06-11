
`timescale 1ns/10ps

module MFE(clk,
           reset,
           busy,
           ready,
           iaddr,
           idata,
           data_rd,
           data_wr,
           addr,
           wen);
    input				clk;
    input				reset;
    output				busy;
    input				ready;
    output	[13:0]		iaddr;
    input	[7:0]		idata;
    input	[7:0]		data_rd;
    output	[7:0]		data_wr;
    output	[13:0]		addr;
    output				wen;
    
    //variable
    reg	[7:0]		idata_load;
    reg	[7:0]		data_rd_load;
    reg	[13:0]		addr_count;
    reg	[13:0]		iaddr;
    reg				busy;

    //map
    reg [7:0]       i;
    reg [7:0]       j;
    reg [4:0]       map_case;

    //mask
    reg [7:0]       mask[0:8];
    reg	[3:0]		mask_count;
    //mask_temp
    reg [7:0]       mask_temp[0:5];

    //sort
    reg [3:0]       sort_count;

    //midian
    reg [7:0]       midian;    
    
    //max
    reg [7:0]       b11;
    reg [7:0]       b12;
    reg [7:0]       b13;
    //med
    reg [7:0]       b21;
    reg [7:0]       b22;
    reg [7:0]       b23;
    //min
    reg [7:0]       b31;
    reg [7:0]       b32;
    reg [7:0]       b33;
    //min
    reg [7:0]       c31;
    reg [7:0]       c22;
    reg [7:0]       c13;
    //med
    reg [7:0]       medfilt_data;

    //reg data
    reg	[7:0]		data_wr;
    reg	[13:0]		addr;
    reg				wen;

    //state variable
    reg [3:0] curt_state;
    reg [3:0] next_state;
    
    //state machine
    always @(*) begin
        case (curt_state)
            0 : 
            begin //initialization
                if( busy == 1 )
                    next_state = 1;
                else
                    next_state = 0;
            end

            1 : //choose map_case
            begin 
                if( mask_count == 9 )
                    next_state = 2;
                else
                    next_state = 1;
            end

            2 : //sorting
            begin
                if( sort_count == 4 )
                    next_state = 4;
                else
                    next_state = 2;
            end

            3 : //mid
            begin
                next_state = 4;                                 
            end

            4 : //write
            begin
                next_state = 5;  
            end

            5 : //check and 進位
            begin
                next_state = 1; 
            end
            
        endcase
    end
    
    
    always @(posedge clk  or posedge reset) begin
         
        if (reset)
        begin
            //reset
            addr_count <= 0;
            busy       <= 0;
            curt_state <= 0;
            mask_count <= 0;
            map_case <= 1;
            i <= 0;
            j <= 0;
        end
        else
        begin            
            curt_state <= next_state; 

                    if ( i == 0 && j == 0)//左上 
                        map_case <= 1;
                    else if( i == 127 && j == 0 )//右上
                        map_case <= 2;
                    else if( i == 0 && j == 127  )//左下
                        map_case <= 3;
                    else if( i == 127 && j == 127 )//右下
                        map_case <= 4;
                    else if( ( i != 0 | i != 127 ) && j == 0 )//上
                        map_case <= 5;
                    else if( ( i == 0 ) && ( (j != 0 && i == 0) | (j != 127 && i == 0)) )//左
                        map_case <= 6;
                    else if( i == 127 && ( (j != 0 && i == 127 ) | (j != 127 && i == 127) ) )//右
                        map_case <= 7;
                    else if( ( i != 0 | i != 127 ) && j == 127 )//下
                        map_case <= 8;
                    else 
                        map_case <= 0;//其他


            case (curt_state)
                0 : 
                begin
                    //當busy=0後，ready就會拉成1
                    if (ready == 1)
                    begin
                        busy  <= 1;
                    end 
                end  

                1 : 
                begin
                    if( j == 128 )
                        begin
                            busy <= 0;  
                        end 
                    
                    case ( map_case )
                        1 : //左上
                        begin
                            if( mask_count != 9 )
                                mask_count <= mask_count + 1;
                            case ( mask_count )                                
                                0 :begin
                                    iaddr <= addr_count - 129;//[0]=n-129
                                end                                
                                1 :begin
                                    iaddr <= addr_count - 128;//[1]=n-128
                                    mask[mask_count-1] <= 0;   
                                end 
                                2 :begin
                                    iaddr <= addr_count - 127;//[2]=n-127
                                    mask[mask_count-1] <= 0; 
                                end
                                3 :begin
                                    iaddr <= addr_count - 1;//[3]=n-1
                                    mask[mask_count-1] <= 0;
                                end
                                4 :begin
                                    iaddr <= addr_count;//[4]=n
                                    mask[mask_count-1] <= 0;
                                end
                                5 :begin
                                    iaddr <= addr_count + 1;//[5]=n+1
                                    mask[mask_count-1] <= idata;
                                end
                                6 :begin
                                    iaddr <= addr_count + 127;//[6]=n+127
                                    mask[mask_count-1] <= idata;
                                end
                                7 :begin
                                    iaddr <= addr_count + 128;//[7]=n+128
                                    mask[mask_count-1] <= 0;
                                end
                                8 :begin
                                    iaddr <= addr_count + 129;//[8]=n+129
                                    mask[mask_count-1] <= idata;
                                end
                                9 :begin
                                    iaddr <= addr_count - 128;//next addr
                                    mask[mask_count-1] <= idata;
                                    mask_count <= 0; 
                                    sort_count <= 0;
                                    //sort_count2 <= 0;
                                end
                                
                            endcase
                        end 
                        2 : //右上
                        begin
                            //邊邊角角 mask2
                            //開始讀輸入進來的值，mask大小為3*3，共會吃到9筆資料，前面幾筆 進行padding  
                            //中心iaddr為127的時候
                            if( mask_count != 9 )
                                mask_count <= mask_count + 1;
                            mask[0] <= 0;
                            mask[1] <= 0;
                            mask[2] <= 0;
                            mask[5] <= 0;
                            mask[8] <= 0;
                            if( mask_count == 2 )
                            begin
                                iaddr <= addr_count - 1;//126
                                mask[mask_count] <= 0;//mask[2]=0  
                            end
                            if( mask_count == 3)
                            begin
                                mask[mask_count] <= idata;//mask[3]=(iaddr=126)
                                iaddr <= addr_count;//127
                            end
                            if( mask_count == 4)
                            begin
                                mask[mask_count] <= idata;//mask[4]=(iaddr=127)
                                iaddr <= addr_count + 127;//254 = 127 + 127
                            end
                            if( mask_count == 6)
                            begin
                                mask[mask_count] <= idata;//mask[6]=(iaddr=254)
                                iaddr <= addr_count + 128;//255 = 127 + 128
                            end
                            if( mask_count == 7)
                            begin
                                mask[mask_count] <= idata;//mask[7]=(iaddr=255)
                            end      
                            if( mask_count == 9 )//歸零
                            begin
                                mask_count <= 0; 
                                sort_count <= 0;
                                //sort_count2 <= 0;
                            end
                        end
                        3 : //左下
                        begin
                            if( mask_count != 9 )
                                mask_count <= mask_count + 1;
                            case ( mask_count )
                                0 :begin
                                    iaddr <= addr_count - 129;//[0]=n-129
                                end                                
                                1 :begin
                                    iaddr <= addr_count - 128;//[1]=n-128
                                    mask[mask_count-1] <= 0;   
                                end 
                                2 :begin
                                    iaddr <= addr_count - 127;//[2]=n-127
                                    mask[mask_count-1] <= idata; 
                                end
                                3 :begin
                                    iaddr <= addr_count - 1;//[3]=n-1
                                    mask[mask_count-1] <= idata;
                                end
                                4 :begin
                                    iaddr <= addr_count;//[4]=n
                                    mask[mask_count-1] <= 0;
                                end
                                5 :begin
                                    iaddr <= addr_count + 1;//[5]=n+1
                                    mask[mask_count-1] <= idata;
                                end
                                6 :begin
                                    iaddr <= addr_count + 127;//[6]=n+127
                                    mask[mask_count-1] <= idata;
                                end
                                7 :begin
                                    iaddr <= addr_count + 128;//[7]=n+128
                                    mask[mask_count-1] <= 0;
                                end
                                8 :begin
                                    iaddr <= addr_count + 129;//[8]=n+129
                                    mask[mask_count-1] <= 0;
                                end
                                9 :begin
                                    iaddr <= addr_count - 128;//next addr
                                    mask[mask_count-1] <= 0;
                                    mask_count <= 0; 
                                    sort_count <= 0;
                                    //sort_count2 <= 0;
                                end                                
                            endcase
                        end
                        4 : //右下
                        begin
                            if( mask_count != 9 )
                                mask_count <= mask_count + 1;
                            case ( mask_count )
                                0 :begin
                                    iaddr <= addr_count - 129;//[0]=n-129
                                end                                
                                1 :begin
                                    iaddr <= addr_count - 128;//[1]=n-128
                                    mask[mask_count-1] <= idata;   
                                end 
                                2 :begin
                                    iaddr <= addr_count - 127;//[2]=n-127
                                    mask[mask_count-1] <= idata; 
                                end
                                3 :begin
                                    iaddr <= addr_count - 1;//[3]=n-1
                                    mask[mask_count-1] <= 0;
                                end
                                4 :begin
                                    iaddr <= addr_count;//[4]=n
                                    mask[mask_count-1] <= idata;
                                end
                                5 :begin
                                    iaddr <= addr_count + 1;//[5]=n+1
                                    mask[mask_count-1] <= idata;
                                end
                                6 :begin
                                    iaddr <= addr_count + 127;//[6]=n+127
                                    mask[mask_count-1] <= 0;
                                end
                                7 :begin
                                    iaddr <= addr_count + 128;//[7]=n+128
                                    mask[mask_count-1] <= 0;
                                end
                                8 :begin
                                    iaddr <= addr_count + 129;//[8]=n+129
                                    mask[mask_count-1] <= 0;
                                end
                                9 :begin
                                    iaddr <= addr_count - 128;//next addr
                                    mask[mask_count-1] <= 0;
                                    mask_count <= 0; 
                                    sort_count <= 0;
                                    //sort_count2 <= 0;
                                end                                
                            endcase
                        end
                        5 : //上
                        begin
                            if( mask_count != 9 )
                                mask_count <= mask_count + 1;
                            mask[0] <= 0;
                            mask[1] <= 0;
                            mask[2] <= 0;
                            if( mask_count == 2 )
                            begin
                                iaddr <= addr_count - 1;
                                mask[mask_count] <= 0;  
                            end
                            if( mask_count == 3 )
                            begin
                                iaddr <= addr_count;
                                mask[mask_count] <= idata;  
                            end
                            if( mask_count == 4)
                            begin
                                mask[mask_count] <= idata;
                                iaddr <= addr_count + 1;
                            end
                            if( mask_count == 5)
                            begin
                                mask[mask_count] <= idata;
                                iaddr <= addr_count + 127;
                            end
                            if( mask_count == 6)
                            begin
                                mask[mask_count] <= idata;
                                iaddr <= addr_count + 128;
                            end
                            if( mask_count == 7)
                            begin
                                mask[mask_count] <= idata;
                                iaddr <= addr_count + 129;
                                //i <= i + 1;
                            end
                            if( mask_count == 8 )
                                mask[mask_count] <= idata;      
                            if( mask_count == 9 )
                            begin
                                mask_count <= 0; 
                                sort_count <= 0;
                                //sort_count2 <= 0;
                                //addr_count <= addr_count + 1;
                            end

                        end                        
                        6 : //左
                        begin
                            if( mask_count != 9 )
                                mask_count <= mask_count + 1;
                            case ( mask_count )
                                1 :begin
                                    iaddr <= addr_count - 128;//[1]=n-128
                                    mask[mask_count-1] <= 0;   
                                end 
                                2 :begin
                                    iaddr <= addr_count - 127;//[2]=n-127
                                    mask[mask_count-1] <= idata; 
                                    mask_temp[mask_count-2] <= idata;
                                end
                                3 :begin
                                    iaddr <= addr_count - 1;//[3]=n-1
                                    mask[mask_count-1] <= idata;
                                    mask_temp[mask_count-2] <= idata;
                                end
                                4 :begin
                                    mask[mask_count-1] <= 0;
                                    iaddr <= addr_count;//[4]=n
                                end
                                5 :begin                                    
                                    iaddr <= addr_count + 1;//[5]=n+1
                                    mask[mask_count-1] <= idata;
                                    mask_temp[mask_count-3] <= idata;
                                end
                                6 :begin
                                    mask[mask_count-1] <= idata;
                                    iaddr <= addr_count + 127;//[6]=n+127                                    
                                    mask_temp[mask_count-3] <= idata;
                                end
                                7 :begin
                                    mask[mask_count-1] <= 0;
                                    iaddr <= addr_count + 128;//[7]=n+128
                                end
                                8 :begin
                                    mask[mask_count-1] <= idata;
                                    iaddr <= addr_count + 129;//[8]=n+129                                    
                                    mask_temp[mask_count-4] <= idata;
                                end
                                9 :begin
                                    iaddr <= addr_count - 128;//next addr
                                    mask[mask_count-1] <= idata;                                    
                                    mask_temp[mask_count-4] <= idata;
                                    mask_count <= 0; 
                                    sort_count <= 0;
                                    //sort_count2 <= 0;
                                end
                                
                            endcase
                        end
                        7 : //右
                        begin
                            if( mask_count != 9 )
                                mask_count <= mask_count + 1;
                            case ( mask_count )
                                0 :begin
                                    iaddr <= addr_count - 129;//[0]=n-129
                                end                                
                                1 :begin
                                    iaddr <= addr_count - 128;//[1]=n-128
                                    mask[mask_count-1] <= idata;   
                                end 
                                2 :begin
                                    iaddr <= addr_count - 127;//[2]=n-127
                                    mask[mask_count-1] <= idata; 
                                end
                                3 :begin
                                    iaddr <= addr_count - 1;//[3]=n-1
                                    mask[mask_count-1] <= 0;
                                end
                                4 :begin
                                    iaddr <= addr_count;//[4]=n
                                    mask[mask_count-1] <= idata;
                                end
                                5 :begin
                                    iaddr <= addr_count + 1;//[5]=n+1
                                    mask[mask_count-1] <= idata;
                                end
                                6 :begin
                                    iaddr <= addr_count + 127;//[6]=n+127
                                    mask[mask_count-1] <= 0;
                                end
                                7 :begin
                                    iaddr <= addr_count + 128;//[7]=n+128
                                    mask[mask_count-1] <= idata;
                                end
                                8 :begin
                                    iaddr <= addr_count + 129;//[8]=n+129
                                    mask[mask_count-1] <= idata;
                                end
                                9 :begin
                                    iaddr <= addr_count - 128;//next addr
                                    mask[mask_count-1] <= 0;
                                    mask_count <= 0; 
                                    sort_count <= 0;
                                    //sort_count2 <= 0;
                                end                                
                            endcase
                        end
                        8 : //下
                        begin
                            if( mask_count != 9 )
                                mask_count <= mask_count + 1;
                            case ( mask_count )
                                0 :begin
                                    iaddr <= addr_count - 129;//[0]=n-129
                                end                                
                                1 :begin
                                    iaddr <= addr_count - 128;//[1]=n-128
                                    mask[mask_count-1] <= idata;   
                                end 
                                2 :begin
                                    iaddr <= addr_count - 127;//[2]=n-127
                                    mask[mask_count-1] <= idata; 
                                end
                                3 :begin
                                    iaddr <= addr_count - 1;//[3]=n-1
                                    mask[mask_count-1] <= idata;
                                end
                                4 :begin
                                    iaddr <= addr_count;//[4]=n
                                    mask[mask_count-1] <= idata;
                                end
                                5 :begin
                                    iaddr <= addr_count + 1;//[5]=n+1
                                    mask[mask_count-1] <= idata;
                                end
                                6 :begin
                                    iaddr <= addr_count + 127;//[6]=n+127
                                    mask[mask_count-1] <= idata;
                                end
                                7 :begin
                                    iaddr <= addr_count + 128;//[7]=n+128
                                    mask[mask_count-1] <= 0;
                                end
                                8 :begin
                                    iaddr <= addr_count + 129;//[8]=n+129
                                    mask[mask_count-1] <= 0;
                                end
                                9 :begin
                                    iaddr <= addr_count - 128;//next addr
                                    mask[mask_count-1] <= 0;
                                    mask_count <= 0; 
                                    sort_count <= 0;
                                    //sort_count2 <= 0;
                                end                                
                            endcase
                        end
                        0 : //中間演算法 129 + 128 + 128
                        //要拆成2個state，然後改 0 這個state的次數 降到4個就好
                        //i == 1 的時候 要做9次 讀全部的直， i != 1 做4次就好
                        begin
                            if( mask_count != 9 )
                                    mask_count <= mask_count + 1;
                                case ( mask_count )
                                    0 :begin
                                        iaddr <= addr_count - 129;//[0]=n-129
                                    end                                
                                    1 :begin
                                        iaddr <= addr_count - 128;//[1]=n-128
                                        //mask[0] <= idata
                                        mask[mask_count-1] <= idata;   
                                    end 
                                    2 :begin
                                        iaddr <= addr_count - 127;//[2]=n-127
                                        //mask[1] <= idata
                                        mask[mask_count-1] <= idata; 
                                        //mask_temp[0] <= mask[1]
                                        mask_temp[mask_count-2] <= idata;
                                    end
                                    3 :begin
                                        iaddr <= addr_count - 1;//[3]=n-1
                                        //mask[2] <= idata
                                        mask[mask_count-1] <= idata;
                                        //mask_temp[1] <= mask[2]
                                        mask_temp[mask_count-2] <= idata;
                                    end
                                    4 :begin
                                        iaddr <= addr_count;//[4]=n
                                        //mask[3] <= idata
                                        mask[mask_count-1] <= idata;
                                    end
                                    5 :begin
                                        iaddr <= addr_count + 1;//[5]=n+1
                                        //mask[4] <= idata
                                        mask[mask_count-1] <= idata;
                                        //mask_temp[2] <= mask[4]
                                        mask_temp[mask_count-3] <= idata;
                                    end
                                    6 :begin
                                        iaddr <= addr_count + 127;//[6]=n+127
                                        mask[mask_count-1] <= idata;
                                        //mask_temp[3] <= mask[5]
                                        mask_temp[mask_count-3] <= idata;
                                    end
                                    7 :begin
                                        iaddr <= addr_count + 128;//[7]=n+128
                                        mask[mask_count-1] <= idata;
                                        
                                    end
                                    8 :begin
                                        iaddr <= addr_count + 129;//[8]=n+129
                                        mask[mask_count-1] <= idata;
                                        
                                        //mask_temp[4] <= mask[7]
                                        mask_temp[mask_count-4] <= idata;
                                    end
                                    9 :begin
                                        iaddr <= addr_count - 128;//next addr
                                        mask[mask_count-1] <= idata;

                                        //mask_temp[5] <= mask[8]
                                        mask_temp[mask_count-4] <= idata;

                                        mask_count <= 0; 
                                        sort_count <= 0;
                                        //sort_count2 <= 0;
                                    end                                
                                endcase 
                            end
                            /*
                            else
                            begin
                                if( mask_count != 9 )
                                    mask_count <= mask_count + 1;
                                case ( mask_count )
                                    0 :begin
                                        mask[mask_count] <= mask_temp[mask_count];   
                                    end                                
                                    1 :begin
                                        mask[mask_count] <= mask_temp[mask_count];
                                        mask_temp[mask_count-1] <= mask_temp[mask_count];
                                        iaddr <= addr_count - 127;//[2]=n-127 
                                    end 
                                    2 :begin
                                        mask[mask_count] <= idata;
                                        mask_temp[mask_count-1] <= idata;
                                    end
                                    3 :begin
                                        mask[mask_count] <= mask_temp[mask_count-1];
                                        //mask_temp[mask_count-1] <= mask_temp[mask_count-1];
                                    end
                                    4 :begin
                                        mask[mask_count] <= mask_temp[mask_count-1];
                                        mask_temp[mask_count-2] <= mask_temp[mask_count-1];
                                        iaddr <= addr_count + 1;//[5]=n+1 
                                    end
                                    5 :begin
                                        mask[mask_count] <= idata;
                                        mask_temp[mask_count-2] <= idata;
                                    end
                                    6 :begin
                                        mask[mask_count] <= mask_temp[mask_count-2];
                                        //mask_temp[mask_count-1] <= mask_temp[mask_count-2];
                                    end
                                    7 :begin
                                        mask[mask_count] <= mask_temp[mask_count-2];
                                        mask_temp[mask_count-3] <= mask_temp[mask_count-2];                                          
                                        iaddr <= addr_count + 129;                                 
                                    end
                                    8 :begin                                        
                                        mask[mask_count] <= idata;    
                                        mask_temp[mask_count-3] <= idata;
                                    end
                                    9 :begin
                                        iaddr <= addr_count - 128;//next addr
                                        mask_count <= 0; 
                                        sort_count <= 0;
                                        //sort_count2 <= 0;
                                    end                                
                                endcase  

                                //test
                                
                                case ( mask_count )
                                    0 :begin
                                        mask[mask_count] <= mask_temp[mask_count];   
                                    end                                
                                    1 :begin
                                        mask[mask_count] <= mask_temp[mask_count];
                                        mask_temp[mask_count-1] <= mask_temp[mask_count];
                                        iaddr <= addr_count - 127;//[2]=n-127 
                                    end 
                                    2 :begin
                                        mask[mask_count] <= idata;
                                        mask_temp[mask_count-1] <= idata;
                                    end
                                    3 :begin
                                        mask[mask_count] <= mask_temp[mask_count-1];
                                        //mask_temp[mask_count-1] <= mask_temp[mask_count-1];
                                    end
                                    4 :begin
                                        mask[mask_count] <= mask_temp[mask_count-1];
                                        mask_temp[mask_count-2] <= mask_temp[mask_count-1];
                                        iaddr <= addr_count + 1;//[5]=n+1 
                                    end
                                    5 :begin
                                        mask[mask_count] <= idata;
                                        mask_temp[mask_count-2] <= idata;
                                    end
                                    6 :begin
                                        mask[mask_count] <= mask_temp[mask_count-2];
                                        //mask_temp[mask_count-1] <= mask_temp[mask_count-2];
                                    end
                                    7 :begin
                                        mask[mask_count] <= mask_temp[mask_count-2];
                                        mask_temp[mask_count-3] <= mask_temp[mask_count-2];                                          
                                        iaddr <= addr_count + 129;                                 
                                    end
                                    8 :begin                                        
                                        mask[mask_count] <= idata;    
                                        mask_temp[mask_count-3] <= idata;
                                    end
                                    9 :begin
                                        iaddr <= addr_count - 128;//next addr
                                        mask_count <= 0; 
                                        sort_count <= 0;
                                        //sort_count2 <= 0;
                                    end                                
                                endcase 
                                
                            end
                            
                        end
                        */
                    endcase
                end

                2 : //3*3 quick sorting
                begin
                            //cloumm sorting
                            b11 <= max(mask[0],mask[1],mask[2]);
                            b21 <= med(mask[0],mask[1],mask[2]);
                            b31 <= min(mask[0],mask[1],mask[2]);

                            b12 <= max(mask[3],mask[4],mask[5]);
                            b22 <= med(mask[3],mask[4],mask[5]);
                            b32 <= min(mask[3],mask[4],mask[5]);
                            
                            b13 <= max(mask[6],mask[7],mask[8]);
                            b23 <= med(mask[6],mask[7],mask[8]);
                            b33 <= min(mask[6],mask[7],mask[8]);
                            
                            //line sorting
                            c31 <= max(b31, b32, b33);
                            c22 <= med(b21, b22, b23);
                            c13 <= min(b11, b12, b13);
                            //find midian 
                            midian <= med(c13, c22, c31);
                            
                            sort_count <= sort_count + 1;
                    
                end                    
                3 : //找 mid 
                begin 
                    //midian <= medfilt_data;
                    //midian <= mask[4];//mid 值                            
                end
                4 : //輸出、寫入中值
                begin 
                    wen <= 1;   
                    addr <= addr_count;     
                    data_wr <= midian;                
                end
                5 : //讀取、檢查中值
                begin 
                    wen <= 0;   
                    addr <= addr_count; 
                    addr_count <= addr_count + 1;       
                    i <= i + 1; 
                    
                    if( i == 127 )
                    begin
                        i <= 0;
                        j <= j + 1;                        
                    end
                          
                end

            endcase            
            
        end   


        
    end       

    function [7:0] max;//if the data is signed number, please add the char signed behind key function; 
            input [7:0] a, b, c;
            begin
                max = (((a >= b) ? a : b) >= c ) ?  ((a >= b) ? a : b) : c;
            end
        endfunction   

        function [7:0] med;
            input [7:0] a, b, c;
            begin
                med = a < b ? (b < c ? b : a < c ? c : a) : (b > c ? b : a > c ? c : a);
            end
	    endfunction

        function [7:0] min;
            input [7:0] a, b, c;
            begin
                min= (((a <= b) ? a : b) <= c ) ?  ((a <= b) ? a : b) : c;
            end
        endfunction


endmodule
        
        
        
        
