# encoding: utf-8

import sys, os, os.path
import argparse
import csv

# Add parent directory to sys.path
parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, parent_dir)

from aux.loadstandarddata import load_empirical_data_into_memory

# for each experiment 2015 and 2018, just look at the switching rounds. What's the probability that they've heard that before as a function of round (and then cumulative)
# This doesn't depend on the model so just run once. Save to tsv and can plot later if needed

NG_SOURCE_FILENAME = ""
OUTPUT_DIR = ""

SWITCH_RECORDS = []
total_rounds_cumulative = 0
total_num_switches = 0
total_heard_before_count = 0
total_said_before_count = 0	
total_de_novo_introductions = 0


def update_subject_experience(subject_dict, ID, ROUND, THEIRNAME, PARTNERNAME):
	agent_experience = subject_dict.get(ID, [])
	agent_experience.append((THEIRNAME, ROUND, PARTNERNAME))
	subject_dict[ID] = agent_experience


def check_exp_switchback_rate(curr_data, curr_exp_name):
	global SWITCH_RECORDS
	# print(curr_data)
	num_switches = 0
	rounds_cumulative = 0
	heard_before_count = 0
	said_before_count = 0
	de_novo_count = 0
	subject_dict = {}
	for row in curr_data:
		assert len(row) == 12

		IS_CONFED_A = row[7]
		IS_CONFED_B = row[11]
		A_NAME = row[6]
		B_NAME = row[10]
		if IS_CONFED_A != "TRUE":
			update_subject_experience(subject_dict, row[4], int(row[5]), A_NAME, B_NAME) # ID, ROUND, THEIRNAME, PARTNERNAME
		if IS_CONFED_B != "TRUE":
			update_subject_experience(subject_dict, row[8], int(row[9]), B_NAME, A_NAME) # ID, ROUND, THEIRNAME, PARTNERNAME


	for subj, record in subject_dict.items():
		ordered_experience = sorted(record, key=lambda x: x[1] )
		# print(ordered_experience)
		rounds_cumulative += len(ordered_experience)
		for round_num in range(1, len(ordered_experience)):
			last_name = ordered_experience[round_num-1][0]
			curr_name = ordered_experience[round_num][0]
			if last_name != curr_name: # found a switch
				num_switches += 1
				experience_so_far = ordered_experience[:round_num]
				heard_names_so_far = [name[2] for name in experience_so_far]
				said_names_so_far = [name[0] for name in experience_so_far]

				said_before, heard_before, denovo = 0, 0, 0
				if curr_name in [name[0] for name in experience_so_far]:
					said_before_count += 1
					said_before = 1
				if curr_name in [name[2] for name in experience_so_far]:
					heard_before_count += 1
					heard_before = 1
				if not said_before and not heard_before:
					de_novo_count += 1
					denovo = 1

				SWITCH_RECORDS.append([curr_exp_name, round_num, subj, curr_name, said_before, heard_before, denovo, said_names_so_far, heard_names_so_far])

	return rounds_cumulative, num_switches, heard_before_count, said_before_count, de_novo_count


def parse_input_args():
	global NG_SOURCE_FILENAME, OUTPUT_DIR

	parser = argparse.ArgumentParser(description = "Name Game Modeling")
	parser.add_argument("--datasourcefile", help="filename for source data", type=str)
	parser.add_argument("--outputdir", help="output directory for results", type=str)
	args = parser.parse_args()

	if args.datasourcefile is None:
		raise Exception("Need to specify path to empirical data")
	else:
		NG_SOURCE_FILENAME = args.datasourcefile

	if args.outputdir is None:
		raise Exception("Need to specify output director")
	else:
		OUTPUT_DIR = args.outputdir


if __name__ == "__main__":
	# print("Calculating name switch-back (re-use) probability... ", end="")

	parse_input_args()

	EXP_TO_NAME_DISTRO_DICT, EXP_KEY_LIST = load_empirical_data_into_memory(NG_SOURCE_FILENAME)

	for curr_exp_name in EXP_KEY_LIST:
		curr_exp_data = EXP_TO_NAME_DISTRO_DICT.get(curr_exp_name)
		rounds_cumulative, num_switches, heard_before_count, said_before_count, de_novo_count = check_exp_switchback_rate(curr_exp_data, curr_exp_name)
		# print(num_switches, heard_before_count, said_before_count)
		total_num_switches += num_switches
		total_heard_before_count += heard_before_count
		total_said_before_count += said_before_count
		total_de_novo_introductions += de_novo_count
		total_rounds_cumulative += rounds_cumulative


	OUTPUT_FILENAME = os.path.join(OUTPUT_DIR, "nameswitchbacks.tsv")
	with open(OUTPUT_FILENAME, 'w') as output_file:
		tsv_output = csv.writer(output_file, delimiter='\t')
		tsv_output.writerow(["exp", "round_num", "agentid", "currname", "saidbefore", "heardbefore", "denovo", "saidsofar", "heardsofar"])
		for switchback in SWITCH_RECORDS:
			tsv_output.writerow(switchback)


	print("Total outputs"+4*" "+"Total Switches"+4*" "+"Said before"+4*" "+"Heard before"+4*" "+"De Novo names after Round 1")
	print(13*"#"+4*" "+14*"#"+4*" "+11*"#"+4*" "+12*"#"+4*" "+27*"#")
	print(f'{total_rounds_cumulative: >13}'+4*" "+f'{total_num_switches: >14}'+4*" "+f'{total_said_before_count: >11}'+4*" "+f'{total_heard_before_count: >12}'+4*" "+f'{total_de_novo_introductions: >27}')

	print("\n")
	print("P(switch)"+4*" "+"P(Said before|switch)"+4*" "+"P(Heard before|switch)"+4*" "+"P(de novo name|switch)"+4*" "+"P(de novo name)")
	print(9*"#" + 4*" " + 21*"#" + 4*" " + 22*"#" + 4*" " + 22*"#" + 4*" " + 15*"#")
	print(f'{total_num_switches/total_rounds_cumulative: >9.2}'+4*" "+f'{total_said_before_count/total_num_switches: >21.2}'+
		4*" "+f'{total_heard_before_count/total_num_switches: >22.2}'+4*" " + f'{total_de_novo_introductions/total_num_switches: >22.2}'  +  4*" "+f'{total_de_novo_introductions/total_rounds_cumulative: >15.2}')