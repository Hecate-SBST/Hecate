#!/bin/bash

echo $1
echo $2

module load matlab/2022a
matlab -nodisplay -nosplash -r "testTranslation('$1',$2); exit();"