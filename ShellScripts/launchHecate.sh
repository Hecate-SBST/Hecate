#!/bin/bash

n_runs=50
file_name=(SettingAFC SettingAT SettingAT2 SettingCC SettingEU SettingFS SettingHPS SettingNN SettingNNP SettingPM SettingSC SettingST SettingTL SettingTUI SettingWT)

for i in "${file_name[@]}";
do
	sbatch -J "Hecate-$i" -n 10 -N 4 --priority=TOP -t 2-00:00 --mem=8G runHecate.sh "$i" "$n_runs";
done