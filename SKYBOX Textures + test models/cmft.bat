@echo off
  if "%~1" == "" goto :setinputfilename
  set "inputfilename=%1"

:checkoutputfilename
  if "%~2" == "" goto :setoutputfilename
  set "outputfilename=%2"

:checkgpuvendor
  if "%~3" == "" goto :setgpuvendor
  set "gpuvendor=%3"

:checkdeviceindex
  if "%~3" == "" goto :run
  set "--deviceIndex=%3"

goto :run

:setinputfilename
  set interactive=true
  set /p "inputfilename=Input filename (with extension):"
  goto :checkoutputfilename

:setoutputfilename
  set interactive=true
  set /p "outputfilename=Output filename (without extension):"
  goto :checkgpuvendor

:setgpuvendor
  set gpuvendor=anyGpuVendor

:run
echo "source %inputfilename% dest %outputfilename% gpu vendor %gpuvendor%"
  cmftRelease ^
         --input %inputfilename% ^
         --filter radiance ^
         --edgefixup warp ^
         --srcFaceSize 0 ^
         --excludeBase true ^
         --mipCount 9 ^
         --generateMipChain false ^
         --glossScale 17 ^
         --glossBias 3 ^
         --lightingModel blinnbrdf ^
         --dstFaceSize 0 ^
         --numCpuProcessingThreads 4 ^
         --useOpenCL true ^
         --clVendor %gpuvendor% ^
         --deviceType gpu ^
         %deviceIndex% ^
         --inputGammaNumerator 1.0 ^
         --inputGammaDenominator 1.0 ^
         --outputGammaNumerator 1.0 ^
         --outputGammaDenominator 1.0 ^
         --output0 %outputfilename% ^
         --output0params dds,bgra8,cubemap ^n

if %interactive% == "" goto end
  pause
:end