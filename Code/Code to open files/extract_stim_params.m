clear all
close all
clc

lines = readlines('C:\Users\firmansssa\Desktop\Elena\Code Regrap\Final code\Characterization\2024-09-25-16-12-22-rec8_stimParams.txt');

stim_params_name = cellstr(split(lines(2), ","));