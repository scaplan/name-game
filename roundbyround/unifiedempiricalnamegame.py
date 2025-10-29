# encoding: utf-8

##  Author: Spencer Caplan
##  CUNY Graduate Center

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
from agents.br_agent import BR_Agent
from agents.br_picksecond_agent import BR_Agent_PickSecond
from agents.cb_agent import CB_Agent
from agents.twothirds_agent import Twothirds_Agent # new for R&R
from agents.luce_agent import Luce_Agent # new for R&R
from agents.luce_withnoise_agent import Luce_Noise_Agent # new for R&R

buffer = 4*" "
VERBOSE_MODE = True
TP_GAUSSIAN_NOISE = 0

MEM_SIZE = 0
BR_NOISE_PARAM = 0.0
BR_NOISE_AS_STR = "0."+str(BR_NOISE_PARAM)
LUCE_NOISE_PARAM = 0.0
LUCE_NOISE_AS_STR = "0."+str(LUCE_NOISE_PARAM)
FIFO_REMOVAL = "FIFO"
UPDATE_RULE = "PENALIZE"

COL_SEP = "\t"
NG_SOURCE_FILENAME = ""
OUTPUT_FILENAME_MAIN = ""
OUTPUT_FILENAME_SIMPLE_NUMBERS = ""




def play_game(curr_data, output_file):
	"""
	Keys are agent/trial type
	Values are lists with two ints
		- the first int is the number of correct predictions
		- the second int is the number of relevant deterministic trials (denominator)

	For the 'headtohead_CBTP' entry the value is a triple of:
		- CB predictions
		- TP predictions
		- total trials
	"""
	global MEM_SIZE, BR_NOISE_PARAM, FIFO_REMOVAL, UPDATE_RULE, TP_GAUSSIAN_NOISE
	
	results_dict = {
					"CB":[0,0],
					"BR":[0,0],
					"TP":[0,0],
					"BR_non_prod":[0,0],
					"Luce_post_TP":[0,0],
					"headtohead_CBTP":[0,0,0],
					"headtohead_TPtwothirds":[0,0,0]
					}

	agent_nums_used = set()

	agent_dict_CB = {}
	agent_dict_BR = {}
	agent_dict_TP = {}
	agent_dict_twothird = {}
	agent_dict_luce = {}

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
			curr_role = curr_speaker_and_output[2]
			round_num = int(curr_speaker_and_output[3])
			interlocutor_num = speaker_pair[interlocutor_index][0]
			interlocutor_name = speaker_pair[interlocutor_index][1]
			isconfed = curr_speaker_and_output[4]
			if isconfed == "TRUE":
				skipbecausebot = True
			else:
				skipbecausebot = False

			if curr_ID not in agent_nums_used:
				agent_nums_used.add(curr_ID)
				agent_dict_CB[curr_ID] = CB_Agent(curr_ID, MEM_SIZE, init_names_list, FIFO_REMOVAL, UPDATE_RULE)
				agent_dict_twothird[curr_ID] = Twothirds_Agent(curr_ID, MEM_SIZE, init_names_list, FIFO_REMOVAL, UPDATE_RULE)
				if LUCE_NOISE_PARAM:
					agent_dict_luce[curr_ID] = Luce_Noise_Agent(curr_ID, MEM_SIZE, init_names_list, FIFO_REMOVAL, UPDATE_RULE, LUCE_NOISE_PARAM) # new 
				else:
					agent_dict_luce[curr_ID] = Luce_Agent(curr_ID, MEM_SIZE, init_names_list, FIFO_REMOVAL, UPDATE_RULE) # new 
				if BR_PICK_SECOND:
					agent_dict_BR[curr_ID] = BR_Agent_PickSecond(curr_ID, MEM_SIZE, init_names_list, FIFO_REMOVAL, UPDATE_RULE, BR_NOISE_PARAM)
				else:
					agent_dict_BR[curr_ID] = BR_Agent(curr_ID, MEM_SIZE, init_names_list, FIFO_REMOVAL, UPDATE_RULE, BR_NOISE_PARAM)
				if not TP_GAUSSIAN_NOISE:
					agent_dict_TP[curr_ID] = TP_Agent(curr_ID, MEM_SIZE, init_names_list, FIFO_REMOVAL, UPDATE_RULE)
				else:
					TP_SHIFTED = round(np.random.normal(0.0, TP_GAUSSIAN_NOISE))
					agent_dict_TP[curr_ID] = TP_Agent(curr_ID, MEM_SIZE, init_names_list, FIFO_REMOVAL, UPDATE_RULE, TP_SHIFTED)

			assert curr_ID in agent_dict_CB and curr_ID in agent_dict_BR and curr_ID in agent_dict_TP
			curr_CB_agent = agent_dict_CB.get(curr_ID)
			curr_BR_agent = agent_dict_BR.get(curr_ID)
			curr_TP_agent = agent_dict_TP.get(curr_ID)
			curr_TwoThirds_agent = agent_dict_twothird.get(curr_ID)
			curr_Luce_agent = agent_dict_luce.get(curr_ID)

			assert round_num == curr_CB_agent.roundsplayed+1 and round_num == curr_TP_agent.roundsplayed+1 and round_num == curr_BR_agent.roundsplayed+1 and round_num == curr_TwoThirds_agent.roundsplayed+1 and round_num == curr_Luce_agent.roundsplayed+1
			output_list = [ExpID, SourcePaper, str(MEM_SIZE), str(BR_NOISE_PARAM), curr_ID, curr_role, isconfed, str(round_num), curr_name, str(interlocutor_num), interlocutor_name,
						   curr_CB_agent.get_name(), curr_BR_agent.get_name(), curr_TP_agent.get_name(), curr_Luce_agent.get_name(),
						   str(curr_CB_agent.in_deterministic_state()), str(curr_BR_agent.in_deterministic_state()),
						   str(curr_TP_agent.in_deterministic_state()), str(curr_CB_agent.eval_name_trial(curr_name)),
						   str(curr_BR_agent.eval_name_trial(curr_name)), str(curr_TP_agent.eval_name_trial(curr_name)), str(curr_Luce_agent.eval_name_trial(curr_name)),
						   curr_CB_agent.mem_to_str_semicolon(), curr_BR_agent.mem_to_str_semicolon(), curr_TP_agent.mem_to_str_semicolon(), curr_Luce_agent.mem_to_str_semicolon()]

			output_string = COL_SEP.join(output_list)
			output_file.write(output_string+"\n")

			###########
			## do evals
			###########
			if not skipbecausebot:
				if curr_CB_agent.in_deterministic_state():
					results_dict.get("CB")[1] += 1
					results_dict.get("CB")[0] += curr_CB_agent.eval_name_trial(curr_name)
				if curr_BR_agent.in_deterministic_state():
					results_dict.get("BR")[1] += 1
					results_dict.get("BR")[0] += curr_BR_agent.eval_name_trial(curr_name)
				if curr_TP_agent.in_deterministic_state():
					results_dict.get("TP")[1] += 1
					results_dict.get("TP")[0] += curr_TP_agent.eval_name_trial(curr_name)
					results_dict.get("Luce_post_TP")[1] += 1
					results_dict.get("Luce_post_TP")[0] += curr_Luce_agent.eval_name_trial(curr_name)
				# BR predictions when TP is below productivity threshold
				if curr_BR_agent.in_deterministic_state() and not curr_TP_agent.in_deterministic_state():
					results_dict.get("BR_non_prod")[1] += 1
					results_dict.get("BR_non_prod")[0] += curr_BR_agent.eval_name_trial(curr_name)
				if curr_CB_agent.in_deterministic_state() and curr_TP_agent.in_deterministic_state():
					results_dict.get("headtohead_CBTP")[2] += 1
					results_dict.get("headtohead_CBTP")[0] += curr_CB_agent.eval_name_trial(curr_name)
					results_dict.get("headtohead_CBTP")[1] += curr_TP_agent.eval_name_trial(curr_name)
				# TP predictions when TP is above productivity threshold but two-thirds isn't yet
				if curr_TP_agent.in_deterministic_state() and not curr_TwoThirds_agent.in_deterministic_state():
					results_dict.get("headtohead_TPtwothirds")[2] += 1
					results_dict.get("headtohead_TPtwothirds")[0] += curr_TP_agent.eval_name_trial(curr_name)
					results_dict.get("headtohead_TPtwothirds")[1] += curr_TwoThirds_agent.eval_name_trial(curr_name)



			######################
			## update agent memory
			######################
			curr_CB_agent.compare_add_name(curr_name, interlocutor_name)
			curr_BR_agent.compare_add_name(curr_name, interlocutor_name)
			curr_TP_agent.compare_add_name(curr_name, interlocutor_name)
			curr_TwoThirds_agent.compare_add_name(curr_name, interlocutor_name)
			curr_Luce_agent.compare_add_name(curr_name, interlocutor_name)
			# print(curr_TP_agent.roundsplayed, curr_TP_agent.check_productivity())
			# print(curr_TwoThirds_agent.roundsplayed, curr_TwoThirds_agent.check_productivity())
			# print()

	return results_dict



def parse_args_and_defaults(args: argparse.Namespace) -> None:
	global NG_SOURCE_FILENAME, OUTPUT_FILENAME_MAIN, OUTPUT_FILENAME_SIMPLE_NUMBERS, MEM_SIZE
	global BR_NOISE_AS_STR, BR_NOISE_PARAM, LUCE_NOISE_AS_STR, LUCE_NOISE_PARAM, FIFO_REMOVAL, UPDATE_RULE
	global VERBOSE_MODE, BR_PICK_SECOND, TP_GAUSSIAN_NOISE

	if args.datasourcefile is None:
		raise Exception("Need to specify path to empirical data")
		# output_path = "model-empirical-results_CBBB2018_V1_SC.csv"
	else:
		NG_SOURCE_FILENAME = args.datasourcefile

	if args.outputfile is None:
		raise Exception("Need to specify output path for main analysis file")
	else:
		OUTPUT_FILENAME_MAIN = args.outputfile

	if args.simplenumberfile is None:
		raise Exception("Need to specify output path for simple number tally")
	else:
		OUTPUT_FILENAME_SIMPLE_NUMBERS = args.simplenumberfile

	if args.memsize is None:
		raise Exception("Need to specify memory size")
	else:
		MEM_SIZE = int(args.memsize)

	if args.brnoise is None:
		raise Exception("Need to specify BR noise level")
	elif args.brnoise > 9:
		raise Exception("BR noise level can't exceed 90%")
	elif args.brnoise < 0:
		raise Exception("BR noise level can't be less than 0%")
	else:
		BR_NOISE_AS_STR = "0."+str(args.brnoise)
		BR_NOISE_PARAM = float(BR_NOISE_AS_STR)

	if args.lucenoise is None:
		LUCE_NOISE_PARAM = 0.0
		LUCE_NOISE_AS_STR = "NormalPureLuce"
	elif args.lucenoise > 9:
		raise Exception("Luce noise level can't exceed 90%")
	elif args.lucenoise < 0:
		raise Exception("Luce noise level can't be less than 0%")
	else:
		LUCE_NOISE_AS_STR = "0."+str(args.lucenoise)
		LUCE_NOISE_PARAM = float(LUCE_NOISE_AS_STR)

	if args.brpicksecond is None:
		raise Exception("Error parsing BR-pick-second flag")
	elif args.brpicksecond == True:
		BR_PICK_SECOND = True
	else:
		BR_PICK_SECOND = False

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

	if args.tpnoise is None:
		TP_GAUSSIAN_NOISE = 0
	elif args.tpnoise > 3:
		raise Exception("TP noise std dev cannot exceed 3.0")
	elif args.tpnoise <= 0:
		raise Exception("TP noise std dev cannot be negative")
	else:
		TP_GAUSSIAN_NOISE = args.tpnoise


	if args.verboseprint:
		VERBOSE_MODE = True
	else:
		VERBOSE_MODE = False



if __name__ == "__main__":

	print("Running name game empirical analysis... ", end="")

	parser = argparse.ArgumentParser(description = "Name Game Modeling")
	parser.add_argument("--datasourcefile", help="filename for source data", type=str)
	parser.add_argument("--outputfile", help="output filename for resulting analysis", type=str)
	parser.add_argument("--simplenumberfile", help="output file for simple, global round-by-round comparison of ABMs", type=str)
	parser.add_argument("--memsize", help="size limit for agent memory buffer", type=int)
	parser.add_argument("--brnoise", help="parameter controlling noisy sampling rate for BR agents", type=int)
	parser.add_argument("--brpicksecond", help="parameter controlling whether the BR+Noise agents should choose randomly or pick the second frequent item in memory", action=argparse.BooleanOptionalAction, default=False)
	parser.add_argument("--lucenoise", help="parameter controlling second-choice sampling rate for Luce agents", type=int)
	parser.add_argument("--poprule", help="Memory pop procedure: FIFO or random sampling", type=str)
	parser.add_argument("--updaterule", help="Memory addition procedure: penalized or buffer", type=str)
	parser.add_argument("--tpnoise", type=float,
                        help="If set then have individual TP agents sample threshold according to normal distribution (mean at TP, std dev. as provided)")
	parser.add_argument("--verboseprint", action=argparse.BooleanOptionalAction,
                        help="Print initial results to terminal (useful for debugging)")
	parse_args_and_defaults(args = parser.parse_args())

	EXP_TO_NAME_DISTRO_DICT, EXP_KEY_LIST = load_empirical_data_into_memory(NG_SOURCE_FILENAME)

	if VERBOSE_MODE:
		print("Exp list: ")
		for exp in EXP_KEY_LIST:
			print("\t ", exp)
		print("Sample row: ", EXP_TO_NAME_DISTRO_DICT.get(EXP_KEY_LIST[1])[0])
		EXCEPTION_THRESHOLD = (MEM_SIZE/np.log(MEM_SIZE))
		PRODUCTIVITY_THRESHOLD = MEM_SIZE - EXCEPTION_THRESHOLD
		print("MEM_SIZE: ", MEM_SIZE, " PRODUCTIVITY_THRESHOLD: ", PRODUCTIVITY_THRESHOLD)

	"""
	Keys are agent/trial type
	Values are lists with two ints
		- the first int is the number of correct predictions
		- the second int is the number of relevant deterministic trials (denominator)

	For the 'headtohead_CBTP' entry the value is a triple of:
		- CB predictions
		- TP predictions
		- total trials
	"""
	global_results_dict = {"CB":[0,0],
						   "BR":[0,0],
						   "TP":[0,0],
						   "Luce_post_TP":[0,0],
						   "BR_non_prod":[0,0],
						   "headtohead_CBTP":[0,0,0],
						   "headtohead_TPtwothirds":[0,0,0]
	}

	with open(OUTPUT_FILENAME_MAIN, 'w') as output_file_main:
		with open(OUTPUT_FILENAME_SIMPLE_NUMBERS, 'w') as output_file_simple:
			header_list = ["DataFile", "SourcePaper", "MemLimit", "BRNoiseParam", "AgentNum", "AgentRole", "IsConfed", "RoundNum", "EmpiricalOutput", "InterlocutorNum",
						   "InterlocutorOutput", "CB-output", "BR-output", "TP-output", "Luce-output", "CB-deterministic", "BR-deterministic", "TP-deterministic",
						   "CB-score", "BR-score", "TP-score", "Luce-score", "CB-memory", "BR-memory", "TP-memory", "Luce-memory"]
			header_str = COL_SEP.join(header_list)
			output_file_main.write(header_str+"\n")

			for curr_exp in EXP_KEY_LIST:
				curr_data = EXP_TO_NAME_DISTRO_DICT.get(curr_exp)
				init_names_list, init_names_dict = get_initial_name_distro(curr_data)
				curr_game_results = play_game(curr_data, output_file_main)

				for agent_compare_type in global_results_dict.keys():
					curr_agent_type_results = global_results_dict.get(agent_compare_type)
					curr_game_results_list = curr_game_results.get(agent_compare_type)
					for index, hits in enumerate(curr_game_results_list):
						curr_agent_type_results[index] += curr_game_results_list[index]

			output_file_simple.write(f"{'Model': >21}{buffer}{'correct rounds': >15}{buffer}{'correct (ABM2)': >15}{buffer}{'total predictions': >15}\n")
			output_file_simple.write((80*"#")+"\n")
			for agent_compare_type in ["CB", "BR", "TP", "Luce_post_TP", "headtohead_CBTP", "BR_non_prod", "headtohead_TPtwothirds"]:
				curr_agent_type_results = global_results_dict.get(agent_compare_type)
				if agent_compare_type == "headtohead_CBTP":
					output_file_simple.write(f"{'Head-to-head (CB, TP):': >21}{buffer}{curr_agent_type_results[0]: >14}{buffer}{curr_agent_type_results[1]: >15}{buffer}{curr_agent_type_results[2]: >17}\n")
				elif agent_compare_type == "headtohead_TPtwothirds":
					output_file_simple.write(f"{'Head-to-head (TP, 2/3rds):': >21}{buffer}{curr_agent_type_results[0]: >10}{buffer}{curr_agent_type_results[1]: >15}{buffer}{curr_agent_type_results[2]: >17}\n")
				else:
					output_file_simple.write(f"{agent_compare_type: >21}:{buffer}{curr_agent_type_results[0]: >14}{buffer}{' ': >14}{buffer}{curr_agent_type_results[1]: >18}\n")
			output_file_simple.write((80*"#")+"\n\n")
			output_file_simple.write(parsepath(OUTPUT_FILENAME_SIMPLE_NUMBERS).stem)

		
	print("Done :) ", end="")

