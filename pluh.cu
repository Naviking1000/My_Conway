#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include "pluh.cuh"

__global__ void GOL(bool* prevFrame, bool* currFrame, int dim)
{
	size_t index = threadIdx.x + blockDim.x * blockIdx.x;
	if (index > dim*dim) return;
	int neighbors = 0;
	int x = index % dim;
	int y = index / dim;
	int2 offsets[8] = { 
		make_int2(-1, -1),
		make_int2(0, -1),
		make_int2(1, -1),
		make_int2(-1, 0),
		make_int2(1, 0),
		make_int2(-1, 1),
		make_int2(0, 1),
		make_int2(1, 1)
	};

	for (int i = 0; i < 8; i++)
	{
		int2 neighborPos = make_int2(x + offsets[i].x, y + offsets[i].y);

		if (neighborPos.x < 0 || neighborPos.x == dim ||
				neighborPos.y < 0 || neighborPos.y == dim)
			continue;

		int neighbor = prevFrame[neighborPos.x + neighborPos.y * dim];
		if (neighbor == 1) neighbors++;

		// if (kernel[i] <= dim*dim)
		// {
		//     if (prevFrame[kernel[i]] == 1)
		//     {
		//         neighbors++;
		//     }
		// }
	}
	if (neighbors < 2)
	{
		currFrame[index] = 0;
	}
	if (neighbors == 3)
	{
		currFrame[index] = 1;
	}
	if (neighbors > 3)
	{
		currFrame[index] = 0;
	}
}

__global__ void SyncPrevFrame(bool* prevFrame, bool* currFrame, int dim)
{
	size_t index = threadIdx.x + blockDim.x * blockIdx.x;
	if (index > dim*dim) return;
	prevFrame[index] = currFrame[index];
}

__global__ void UpdateBuffer(bool* currFrame, uint8_t* buf, int dim, bool paused)
{
	size_t index = threadIdx.x + blockDim.x * blockIdx.x;
	if (index > dim*dim) return;
	size_t bufIndex = index * 4;
	if (currFrame[index] == 1)
	{
		buf[bufIndex] = 0xff;
		buf[bufIndex + 1] = 0xff;
		buf[bufIndex + 2] = 0xff;
	}
	else
	{
		uint8_t blue = paused ? 0xff : 0x00;
		buf[bufIndex] = 0x00;
		buf[bufIndex + 1] = 0x00;
		buf[bufIndex + 2] = blue;
	}
}

int Pluh::SigmaBoy()
{
	imageSize = width * width * 4;
	cudaMallocManaged(&buf, imageSize);
	cudaMallocManaged(&prevFrame, width*width);
	cudaMallocManaged(&currFrame, width*width);
	for (int i = 0; i < imageSize; i++)
	{
		buf[i] = 0xff;
	}
	for (int i = 0; i < width*width; i++)
	{
		int pixel = rand() % 2;
		currFrame[i] = pixel == 1;
		prevFrame[i] = pixel == 1;
	}

	return 0;
}

void Pluh::Simulate()
{
	int size = width*width;
	int blockSize = 256;
	int blocks = (size + blockSize - 1) / blockSize;

	SyncPrevFrame<<<blocks, blockSize>>>(prevFrame, currFrame, width);
	GOL<<<blocks, blockSize>>>(prevFrame, currFrame, width);
}

void Pluh::DrawPixel(int x, int y, bool value)
{
	size_t pixelIndex = y * width + x;

	if (pixelIndex > width*width) return;

	currFrame[pixelIndex] = value;
	prevFrame[pixelIndex] = value;
	cudaDeviceSynchronize();
}

void Pluh::ClearGrid()
{
	for (int i = 0; i < width*width; i++)
	{
		prevFrame[i] = 0;
		currFrame[i] = 0;
	}
	cudaDeviceSynchronize();
}

uint8_t* Pluh::GetBuf(bool paused)
{
	int size = width*width;
	int blockSize = 256;
	int blocks = (size + blockSize - 1) / blockSize;

	UpdateBuffer<<<blocks, blockSize>>>(currFrame, buf, width, paused);
	cudaDeviceSynchronize();
	return buf;
}

size_t Pluh::GetBufSize()
{
	return imageSize;
}

void Pluh::End()
{
	cudaFree(buf);
	cudaFree(prevFrame);
	cudaFree(currFrame);
}

Pluh::Pluh(int width)
{
	this->width = width;
}
