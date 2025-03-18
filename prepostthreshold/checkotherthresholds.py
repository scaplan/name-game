# encoding: utf-8

import sys, os, os.path
import numpy as np
import argparse
import random

# Add parent directory to sys.path
parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, parent_dir)

from aux.loadstandarddata import *
from pathlib import Path as parsepath


from agents.tp_agent import TP_Agent

MEM_SIZE = 12
FIFO_REMOVAL = "FIFO"
UPDATE_RULE = "BUFFER"

COL_SEP = "\t"
NG_SOURCE_FILENAME = ""
OUTPUT_FILENAME_MAIN = ""



def find_first_TP_hits(curr_data, thresh):
	global MEM_SIZE, FIFO_REMOVAL, UPDATE_RULE

	agent_network_firsthit_dict = {}
	agent_nums_used = set()
	agent_dict_TP = {}
	agent_dict_TP_FirstHit = {}

	for curr_row in curr_data:
		LocalRowNum = curr_row[0]
		ExpID = curr_row[1]
		SourcePaper = curr_row[2]
		OrigExpNum = curr_row[3]
		speaker_A_idnum = curr_row[4]
		speaker_A_round_number = curr_row[5]
		speaker_A_empirical_output = curr_row[6]
		speaker_A_isconfed = curr_row[7]
		speaker_B_idnum = curr_row[8]
		speaker_B_round_number = curr_row[9]
		speaker_B_empirical_output = curr_row[10]
		speaker_B_isconfed = curr_row[11]

		speaker_pair = [(speaker_A_idnum, speaker_A_empirical_output, "A", speaker_A_round_number, speaker_A_isconfed),
						(speaker_B_idnum, speaker_B_empirical_output, "B", speaker_B_round_number, speaker_B_isconfed)]

		for index, curr_speaker_and_output in enumerate(speaker_pair):
			interlocutor_index = (index + 1) % 2 # this gets the index of interlocutor
			curr_ID = curr_speaker_and_output[0]
			curr_name = curr_speaker_and_output[1]
			round_num = int(curr_speaker_and_output[3])
			interlocutor_name = speaker_pair[interlocutor_index][1]

			agent_network_ID = SourcePaper + "_" + curr_ID

			if curr_ID not in agent_nums_used:
				agent_nums_used.add(curr_ID)
				agent_dict_TP[curr_ID] = TP_Agent(curr_ID, MEM_SIZE, init_names_list, FIFO_REMOVAL, UPDATE_RULE)

			assert curr_ID in agent_dict_TP
			curr_TP_agent = agent_dict_TP.get(curr_ID)

			if curr_TP_agent.bizarro_world_check_prod(thresh):
				if agent_network_ID not in agent_network_firsthit_dict:
					agent_network_firsthit_dict[agent_network_ID] = round_num

			######################
			## update agent memory
			######################
			curr_TP_agent.compare_add_name(curr_name, interlocutor_name)

	return agent_network_firsthit_dict


def play_game(curr_data, agent_network_firsthit_dict, thresh):
	global MEM_SIZE, FIFO_REMOVAL, UPDATE_RULE

	agent_nums_used = set()
	agent_dict_TP = {}
	agent_dict_TP_FirstHit = {}
	agent_dict_BR = {}

	curr_rows = []

	for curr_row in curr_data:
		LocalRowNum = curr_row[0]
		ExpID = curr_row[1]
		SourcePaper = curr_row[2]
		OrigExpNum = curr_row[3]
		speaker_A_idnum = curr_row[4]
		speaker_A_round_number = curr_row[5]
		speaker_A_empirical_output = curr_row[6]
		speaker_A_isconfed = curr_row[7]
		speaker_B_idnum = curr_row[8]
		speaker_B_round_number = curr_row[9]
		speaker_B_empirical_output = curr_row[10]
		speaker_B_isconfed = curr_row[11]

		speaker_pair = [(speaker_A_idnum, speaker_A_empirical_output, "A", speaker_A_round_number, speaker_A_isconfed),
						(speaker_B_idnum, speaker_B_empirical_output, "B", speaker_B_round_number, speaker_B_isconfed)]


		for index, curr_speaker_and_output in enumerate(speaker_pair):
			interlocutor_index = (index + 1) % 2 # this gets the index of interlocutor
			curr_ID = curr_speaker_and_output[0]
			curr_name = curr_speaker_and_output[1]
			round_num = int(curr_speaker_and_output[3])
			interlocutor_num = speaker_pair[interlocutor_index][0]
			interlocutor_name = speaker_pair[interlocutor_index][1]
			isconfed = curr_speaker_and_output[4]

			agent_network_ID = SourcePaper + "_" + curr_ID
			agent_first_hit_TP = agent_network_firsthit_dict.get(agent_network_ID)
			if agent_first_hit_TP:
				curr_TP_round = round_num - agent_first_hit_TP
			else:
				curr_TP_round = None

			coord_success = "1" if curr_name == interlocutor_name else "0"

			if curr_ID not in agent_nums_used:
				agent_nums_used.add(curr_ID)
				agent_dict_TP[curr_ID] = TP_Agent(curr_ID, MEM_SIZE, init_names_list, FIFO_REMOVAL, UPDATE_RULE)

			assert curr_ID in agent_dict_TP
			curr_TP_agent = agent_dict_TP.get(curr_ID)

			assert round_num == curr_TP_agent.roundsplayed+1 
			output_list = [ExpID, SourcePaper, str(MEM_SIZE), curr_ID, isconfed, str(round_num), curr_name, str(interlocutor_num), interlocutor_name, str(thresh),
						   str(curr_TP_round), str(agent_first_hit_TP), coord_success]

			if (speaker_A_isconfed == "FALSE" and speaker_B_isconfed == "FALSE"):
				curr_rows.append(output_list)

			######################
			## update agent memory
			######################
			curr_TP_agent.compare_add_name(curr_name, interlocutor_name)

	return curr_rows



def parse_args_and_defaults(args: argparse.Namespace) -> None:
	global NG_SOURCE_FILENAME, OUTPUT_FILENAME_MAIN, MEM_SIZE
	global FIFO_REMOVAL, UPDATE_RULE

	if args.datasourcefile is None:
		raise Exception("Need to specify path to empirical data")
	else:
		NG_SOURCE_FILENAME = args.datasourcefile

	if args.outputfile is None:
		raise Exception("Need to specify output path for main analysis file")
	else:
		OUTPUT_FILENAME_MAIN = args.outputfile

	if args.memsize is None:
		raise Exception("Need to specify memory size")
	else:
		MEM_SIZE = int(args.memsize)

	if args.poprule is None:
		raise Exception("Need to provide memory pop procedure (FIFO or random)")
	elif args.poprule not in ["FIFO", "BAG"]:
		raise Exception("Possible memory pop procedures are FIFO or BAG")
	else:
		FIFO_REMOVAL = args.poprule

	if args.updaterule is None:
		raise Exception("Need to provide memory update procedure (BUFFER or PENALIZE)")
	elif args.updaterule not in ["BUFFER", "PENALIZE"]:
		raise Exception("Possible memory update procedures are BUFFER or PENALIZE")
	else:
		UPDATE_RULE = args.updaterule



if __name__ == "__main__":

	print("Running P(coord) analysis (pre-post TP)... ", end="")

	parser = argparse.ArgumentParser(description = "Name Game Modeling")
	parser.add_argument("--datasourcefile", help="filename for source data", type=str)
	parser.add_argument("--outputfile", help="output filename for resulting analysis", type=str)
	parser.add_argument("--memsize", help="size limit for agent memory buffer", type=int)
	parser.add_argument("--poprule", help="Memory pop procedure: FIFO or random sampling", type=str)
	parser.add_argument("--updaterule", help="Memory addition procedure: penalized or buffer", type=str)
	parse_args_and_defaults(args = parser.parse_args())

	EXP_TO_NAME_DISTRO_DICT, EXP_KEY_LIST = load_empirical_data_into_memory(NG_SOURCE_FILENAME)


	with open(OUTPUT_FILENAME_MAIN, 'w') as output_file_main:
		header_list = ["DataFile", "SourcePaper", "MemLimit", "AgentNum", "IsConfed", "RoundNum", "EmpiricalOutput", "InterlocutorNum",
					   "InterlocutorOutput", "Thresh", "Thresh-Round", "FirstHit", "CoordSuccess"]
		header_str = COL_SEP.join(header_list)
		output_file_main.write(header_str+"\n")

		all_runs_all_thresholds = []
		for curr_exp in EXP_KEY_LIST:
			curr_data = EXP_TO_NAME_DISTRO_DICT.get(curr_exp)
			init_names_list, init_names_dict = get_initial_name_distro(curr_data)

			for thresh in range(1, MEM_SIZE+1):
				agent_network_firsthit_dict = find_first_TP_hits(curr_data, thresh) # passing in particular threshold
				curr_run_rows = play_game(curr_data, agent_network_firsthit_dict, thresh)
				all_runs_all_thresholds.append(curr_run_rows)

		for run in all_runs_all_thresholds:
			for row in run:
				output_string = COL_SEP.join(row)
				output_file_main.write(output_string+"\n")

		
	print("Done :)", end="")

