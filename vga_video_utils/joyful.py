import cv2 as cv


def convert_frame(frame):
	"""Convert 256 bit rgb to 8 bit
	frame: opencv image
	"""
	bytes_int = []
	rows,cols,_ = frame.shape
	# print(frame.shape)
    # breakpoint()
	# breakpoint()
	# cnt = 4

	for i in range(rows):
		for j in range(cols):
			# if cnt != 4:
			# 	cnt += 1
			# 	continue
			# else: 
			# 	cnt = 0

			pixel = frame[i,j]
			# breakpoint()
			# eight_bit_pixel = (round(pixel[0]*7/255) << 5) \
			# 				+ (round(pixel[1]*7/255) << 2) \
			# 				+ (round(pixel[2]*3/255))

			eight_bit_pixel = (round(pixel[2]*3/255) << 6) \
							+ (round(pixel[1]*7/255) << 3) \
							+ (round(pixel[0]*7/255))
			# breakpoint()
			bytes_int.append(eight_bit_pixel)

	# breakpoint()
	# return bytes(bytes_int)
	return bytes_int


def get_img_list(img_path):

	img = cv.imread(img_path)

	print(img.shape)

	img_test1 = cv.resize(img, (800, 600))
	# cv.imshow('resize0', img_test1)
	# cv.waitKey()

	return convert_frame(img_test1)


def image():
    # cv.waitKey()

    # img_path_list = ["test.jpg", "test2.jpg", "test3.jpg"]
    # img_path_list = ["test.jpg", "test2.jpg"]
    img_path_list = ["test3.jpg", "test2.jpg", "test.jpg"]

    reg8 = []

    for item in img_path_list:
        reg8 += get_img_list(item)

    # breakpoint()

    write_reg8 = []
    cnt = 0
    for item in reg8:
        if cnt == 0:
            write_reg8.append(item)
        # else:
        # 	write_reg8.append(0)
        cnt += 1
        cnt = cnt % 4

    with open("image.bin", "wb") as fw:
        fw.write(bytes(write_reg8))

    print(len(write_reg8))


def video():
    name = "kun20.flv"
    print(name)

    reg8 = []

    video = cv.VideoCapture(name)
    video.set(cv.CAP_PROP_FPS, 10) # 10 frames every second
 
    # with Bar('video...') as bar:
    i = 0
    counter = 0
    while True:
        ret, frame = video.read()
        # breakpoint()
        if not ret:
            break

        if counter == 0:
            counter += 1
        else:
            counter += 1
            counter = counter % 3
            continue
        # if i >= 300 and i % 3 == 0 and i < 300+3*130: # output 130 frames starting from 300
            # all frames but 10 fps
        b = cv.resize(frame, (200, 150), 
            fx=0, fy=0, interpolation=cv.INTER_CUBIC)

        reg8 += convert_frame(b)
        # breakpoint()
        # compressed_frame = compress_frame(converted_frame, new_resolution[0] * new_resolution[1])
        i += 1
        counter += 1

        if i == 120:
            break
        else:
            print(i)
            # bar.next()
    video.release()
    with open(f"{name.rstrip('.flv')}.bin", "wb") as fw:
        fw.write(bytes(reg8))

    print(len(reg8))

video()
