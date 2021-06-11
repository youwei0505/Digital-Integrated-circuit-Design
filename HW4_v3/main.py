import numpy as np
from numpy.lib.function_base import median
import cv2
import random
from matplotlib import pyplot as plt


# 讀取圖檔
img = cv2.imread('./image.jpg')

# 顯示圖片
#cv2.imshow('image', img)
# 等待圖片，任一按鍵
# cv2.waitKey(0)
# 關閉圖片
# cv2.destroyAllWindows()



# Function to convert RGB Image to GrayScale
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
# dsize
dsize = (128, 128)
# resize image
output = cv2.resize(gray, dsize)
# salt and pepper

def sp_noise(image,prob):
    
    # Add salt and pepper noise to image
    # prob: Probability of the noise
    
    output = np.zeros(image.shape,np.uint8)
    thres = 1 - prob 
    for i in range(image.shape[0]):
        for j in range(image.shape[1]):
            rdn = random.random()
            if rdn < prob:
                output[i][j] = 0
            elif rdn > thres:
                output[i][j] = 255
            else:
                output[i][j] = image[i][j]
    return output
    
noise_img = sp_noise(output,0.02)
print('Noise_img sixe' , noise_img.shape[0] , '*' , noise_img.shape[1] )

# write dat file
file_name = './img.dat'
file = open(file_name,"w")
for i in range(noise_img.shape[0]) :
    for j in range(noise_img.shape[1]) :
        # print(hex(noise_img[i][j])[2:4])
        file.write(hex(noise_img[i][j])[2:4]+'\n')        
file.close


# 第2張圖

border= cv2.copyMakeBorder(noise_img,1,1,1,1,cv2.BORDER_CONSTANT)

# write dat file
file_name = './border.dat'
file = open(file_name,"w")
for i in range(border.shape[0]) :
    for j in range(border.shape[1]) :
        # print(hex(noise_img[i][j])[2:4])
        file.write(hex(border[i][j])[2:4]+'\n')        
file.close

print('bordered sixe' , border.shape[0] , '*' , border.shape[1] )
# print(border.shape[1])


# 寫入golden.dat 
file_name = './golden.dat'
file = open(file_name,"w")
# 從[1,1]~[128,128]
for l in range ( 1,129 ) :
    for m in range ( 1,129 ) :        
        array = []
        # print(  l , ',' , m , ':', array)    
        for j in range ( l-1 , l+2 ):
            for i in range ( m-1 , m+2 ): 
                # print( '[' , j , ',' , i , ']' , hex(border[j][i])[2:4])
                value = hex(border[j][i])[2:4]
                array.append(value)
        # print('\n')
        # print(  l , ',' , m , ':', array)
        array.sort()
        # print(  l , ',' , m , ':', array , array[4])
        file.write(array[4]+'\n')   
file.close



