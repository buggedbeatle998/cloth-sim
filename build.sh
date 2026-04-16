if [ $# -eq 0 ]; then
    echo "Please supply a project name!"
else
    rm shd/*
    cd src/shd/
    for file in *; do
        glslangValidator -G $file -o ../../shd/${file}.spv
    done
    cd ../../
    if [ -f bin/$1 ]; then
        rm bin/$1
    fi
    cd build/
    cmake ../ -DPROJECT_NAME=$1
    cmake --build .
    cd ../bin/
    if [ -f $1 ]; then
        ./$1
    fi
    cd ../
fi
