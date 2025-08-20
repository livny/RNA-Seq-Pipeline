#include <iostream>
#include <string>
#include <fstream>
#include <iomanip>
#include <cctype>
#include <math.h>   
#include <stdlib.h>   
#include <cstring>

#include "SIPHTseq_info.h"

struct SAM
{
	string ID;
	int FLAG;
	string RNAME;
	float START;
	float END;
	int MAPQ;
	string CIGAR;
	string RNEXT;
	int PNEXT;
	int TFLAG_num;
	string SEQ;
	char QUAL[500];
	char STRAND;
	char PAIRED;
};

int const FLAG_num=12;
int f[FLAG_num];

using namespace std;

void flag_parse (int);
void decToBin (int, int, int);
int CIGAR_to_len(string);
 
int main (int argc, char* argv[])
{

	string SAM_input=argv[1];			// path to SAM file
	string coords_output=argv[2];
	string metrics_output=argv[3];			
	string ACC_file=argv[4];			
	string rev=argv[5];			
	
	int min_len=0;
	
	if(argc==7)
		min_len=atoi(argv[6]);		 // added 12/24	

	int count, n, i;
	
	string REF_FILTER="N";
	
	for (i = 0; i < argc; ++i)
	{
		string option=argv[i];
		if(option=="-REF_FILTER")
			REF_FILTER=argv[i+1];
		
	}
	
	struct SAM S[2];

	char input [10000];
	double total_reads=0;
	double total_paired=0;
	double total_proper=0;
	double total_not_proper=0;
	double total_frags=0;
	double total_len=0;
	double total_mapped=0;
	double total_short=0;

	int total_qual;
	int c;
	string s;
	
	char strand_temp;
	
	ifstream InFile1,InFile2,InFile3;
	ofstream OutFile1, OutFile2;
		
	int PAIR=-1; 
	int PROP =-1; 
	int R_UM=-1; 
	int M_UM=-1; 
	int R_REV=-1; 
	int M_REV=-1; 
	int FIRST=-1; 
	int SECOND=-1; 
	int NOT_PRIMARY=-1; 
	int NOT_PF=-1; 
	int DUP=-1; 
	int SUPP_ALIGN=-1; 
	char TOO_SHORT;
	int len;

	InFile1.open(SAM_input.c_str());
	if (!InFile1)
	{
		cerr << "Error opening file '"<<SAM_input<<"'.\n\n";
		exit(1);
	}
	InFile2.open(ACC_file.c_str());
	if (!InFile2)
	{
		cerr << "Error opening file '"<<ACC_file<<"'.\n\n";
		exit(1);
	}
	OutFile1.open(coords_output.c_str());
	if (!OutFile1)
	{
		cerr << "Error opening file '"<<coords_output<<"'.\n\n";
		exit(1);
	}
	OutFile2.open(metrics_output.c_str());
	if (!OutFile2)
	{
		cerr << "Error opening file '"<<metrics_output<<"'.\n\n";
		exit(1);
	}
	
	
		/*
	InFile2.open(FLAG_input.c_str());
	if (!InFile2)
	{
		cerr << "Error opening file '"<<FLAG_input<<"'.\n\n";
		exit(0);
	}
	*/
	
	int numACC = FILE_LINE_COUNT(ACC_file);
	
	string ACC[numACC];
	double ACC_reads[numACC];
	
	for(count=0; count < numACC; count++)
	{
		InFile2 >> ACC[count];
		ACC_reads[count]=0;
	}
	
// 	int FLAG_FILTER[FLAG_num];
// 	
// 	int PAIR_CHOICE=-2; 
// 	int PROP_CHOICE=-2; 
// 	int R_UM_CHOICE=-2; 
// 	int M_UM_CHOICE=-2; 
// 	int R_REV_CHOICE=-2; 
// 	int M_REV_CHOICE=-2; 
// 	int FIRST_CHOICE=-2; 
// 	int SECOND_CHOICE=-2; 
// 	int NOT_PRIMARY_CHOICE=-2; 
// 	int NOT_PF_CHOICE=-2; 
// 	int DUP_CHOICE=-2; 
// 	int SUPP_ALIGN_CHOICE=-2; 
// 	
// 
// 	for(count=1; count < FLAG_num+1; count++)
// 	{
// 		InFile2 >> FLAG_FILTER[count];
// 	}
// 	
// 	
// 	n=0;	
// 	PAIR_CHOICE=FLAG_FILTER[FLAG_num-n++]; 
// 	PROP_CHOICE=FLAG_FILTER[FLAG_num-n++]; 
// 	R_UM_CHOICE=FLAG_FILTER[FLAG_num-n++];
// 	M_UM_CHOICE=FLAG_FILTER[FLAG_num-n++];
// 	R_REV_CHOICE=FLAG_FILTER[FLAG_num-n++];
// 	M_REV_CHOICE=FLAG_FILTER[FLAG_num-n++];
// 	FIRST_CHOICE=FLAG_FILTER[FLAG_num-n++]; 
// 	SECOND_CHOICE=FLAG_FILTER[FLAG_num-n++];
// 	NOT_PRIMARY_CHOICE=FLAG_FILTER[FLAG_num-n++];
// 	NOT_PF_CHOICE=FLAG_FILTER[FLAG_num-n++];
// 	DUP_CHOICE=-FLAG_FILTER[FLAG_num-n++]; 
// 	SUPP_ALIGN_CHOICE=FLAG_FILTER[FLAG_num-n++];
	
	cerr << "Reading in reads"<< endl;
	
	count=0;
	while (1)
	{
				
		InFile1 >> S[1].ID;
		
		if(InFile1.eof())
			break;
		
		if(S[1].ID[0]=='@')
		{
			InFile1.getline(input, 10000);
			continue;

		}
		count++;
		TOO_SHORT='N';
		InFile1 >> S[1].FLAG >> S[1].RNAME >> S[1].START >> S[1].MAPQ >> S[1].CIGAR >> S[1].RNEXT >> S[1].PNEXT >> S[1].TFLAG_num >> S[1].SEQ >> S[1].QUAL;
		InFile1.getline(input, 10000);
		len=strlen(S[1].QUAL);

		if(len < min_len)		// added 12/24	
		{
			TOO_SHORT='Y';
			total_short++;		 	
			//cerr << "*******	" << S[1].ID << " " << S[1].FLAG << " " << FIRST << " " << R_REV << " " << M_REV << " " << M_UM << " " << len << endl;
		}
	
		//cerr << S[1].ID << " " << S[1].FLAG << " " << FIRST << " " << R_REV << " " << M_REV << " " << M_UM << " " << len << endl;
		
		//cerr << S[1].ID << endl;
		S[1].STRAND='0';		
		S[1].PAIRED='N';
		total_reads++;		
		
		if(count % 1000000 == 0)
			cerr << "Read in "<<count/1e6<< " million total_reads so far"<< endl;
		
		//cerr << REF_FILTER << " " << S[1].RNAME << endl;

		if((REF_FILTER=="N" || REF_FILTER==S[1].RNAME) && TOO_SHORT=='N')
		{
			total_qual=0;
			
			for(n=0; n < len; n++)
			{
				c=S[1].QUAL[n];
				total_qual=total_qual+(c-33);
			}
			//cerr << total_qual/len << endl;
					
			
			if(S[1].FLAG>0)
				flag_parse (S[1].FLAG);
			n=0;	
			PAIR=f[FLAG_num-n++]; 
			PROP=f[FLAG_num-n++]; 
			R_UM=f[FLAG_num-n++]; 
			M_UM=f[FLAG_num-n++]; 
			R_REV=f[FLAG_num-n++]; 
			M_REV=f[FLAG_num-n++]; 
			FIRST=f[FLAG_num-n++]; 
			SECOND=f[FLAG_num-n++]; 
			NOT_PRIMARY=f[FLAG_num-n++]; 
			NOT_PF=f[FLAG_num-n++]; 
			DUP=f[FLAG_num-n++]; 
			SUPP_ALIGN=f[FLAG_num-n]; 
									
			/*
			for(n=1; n < FLAG_num+1; n++)
				cout <<f[n];
			cout << endl;
			*/
			
			if(S[1].FLAG==0)
				S[1].STRAND='+';
			if(S[1].FLAG==16)
				S[1].STRAND='-';

				
			if(FIRST==1)
			{
				
				// modified from if(R_REV==0 || M_REV==1 ) 7/3/23			

				if(R_REV==0 || (M_REV==1 && M_UM==0))			
					S[1].STRAND='-';
				// modified from if(R_REV==1 || M_REV==0) 7/3/23			
				if(R_REV==1 || (M_REV==0 && M_UM==0))			
					S[1].STRAND='+';
			}
			
			
			if(SECOND==1)
			{
				if(R_REV==1 || M_REV==0 )			
					S[1].STRAND='-';
				if(R_REV==0 || M_REV==1)			
					S[1].STRAND='+';
			}
			
			
			//cerr << S[1].STRAND << " strand" << endl;

			//
			
			//S[1].END=S[1].START+76;
				
			S[1].END=S[1].START+CIGAR_to_len(S[1].CIGAR);
			//
			
			OutFile1.setf(ios::fixed, ios::floatfield);
			OutFile1.setf(ios::showpoint);
			OutFile1.precision(0);
			
			if(rev=="Y")
			{
				if(S[1].STRAND=='+')
					strand_temp='-';
				if(S[1].STRAND=='-')
					strand_temp='+';
				S[1].STRAND=strand_temp;
			}
			
			if(PAIR==1)
				total_paired++;
			
			if(R_UM==0)
			{	
				total_mapped++;
				for(n=0; n < numACC; n++)
				{
				
					if(S[1].RNAME==ACC[n])
						ACC_reads[n]++;
				}
			}
			if(PROP==1)
			{
				
				total_proper++;
		
				if(SECOND==1)
				{
					if(S[0].START<=S[1].START)
						S[1].START=S[0].START;
					else						
						S[1].END=S[0].END;
					S[1].PAIRED='Y';
					OutFile1 << S[1].RNAME << "	" << S[1].START  << "	" << S[1].END << "	" << S[1].STRAND << "	" << S[1].PAIRED << " " << S[1].ID << ":" << S[1].PAIRED << endl;
					total_frags++;
					total_len+=S[1].END-S[1].START;
				}
			}
			
			if((PROP==0 && R_UM==0) || (PROP==0 && S[1].FLAG==0) )
			{
				OutFile1 << S[1].RNAME << "	" << S[1].START  << "	" << S[1].END << "	" << S[1].STRAND << "	" << S[1].PAIRED << " " << S[1].ID << ":" << FIRST << endl;
				total_frags++;
			}
			S[0]=S[1];
		}
	}
	OutFile2.setf(ios::fixed, ios::floatfield);
	OutFile2.setf(ios::showpoint);
	OutFile2.precision(0);
	

	OutFile2 << "@Total_reads:	" << total_reads << endl;
	//OutFile2 << "@Total_frags:	" << total_frags << endl;
	OutFile2.precision(1);
	OutFile2 << "@%_reads_shorter_than " << min_len << ":	" << total_short/total_reads*100 << endl;
	OutFile2 << "@%_reads_properly_mapped_to_any_reference:	" << total_mapped/total_reads*100 << endl;
	OutFile2 << "@%_reads_properly_mapped_in_pairs:	" << total_proper/total_mapped*100 << endl;
	OutFile2 << "@Avge_insert_length:	" << total_len/(total_proper/2) << endl;	
	OutFile2.precision(0);

	for(n=0; n < numACC; n++)
		OutFile2 << "@Total_reads_aligned_to_" << ACC[n] << ":	" << ACC_reads[n] << endl;

	//cout <<total_proper << " \t" << SAM_num << " \t" <<  total_paired << endl;
	 
	InFile1.close();
	
	return 0;
}



void flag_parse (int decimal)
{
	
	int n;
	
	for(n=1; n < FLAG_num+1; n++)
		f[n] = 0;
 	
	
	if (decimal > 0)
		decToBin (decimal, 2, FLAG_num+1); 
	else
		cout << "" << decimal << " is not a non-negative integer. " << endl;
	
}

void decToBin(int num, int base, int i)
{
	i--;
	if (num > 0)
	{
		decToBin (num/base, base, i);
		f[i] = num % base;
		//cout << f[i] << "\t" << i << endl ;
	}
}

int CIGAR_to_len(string s)
{
	int x=5;
	char c[x];
	
	int count, p, i, y, len;
	count=0;
	len=0;
	p=0;
	i=0;
	y=0;
	len=0;
	
	while(s[count] != '\0')
  	{	
		if (isdigit(s[count]))	
			c[i++]=s[count];
		
		if (!isdigit(s[count]))	
		{
			if(s[count]=='M' || s[count]=='D')
				len=len+atoi(c);	
			
			for(p=0; p < x; p++)
				c[p]=0;
			
			i=0;
		}
		count++;	
	}
	return len;
	
}


