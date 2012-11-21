#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <map>
#include <list>
#include <stdlib.h>

using namespace std;

struct Individual
{
	string id[2];
	string pid[2];
	char sex;
	string aff;
};

int main (int argc, char* argv[]) 
{
	string line, discard;
	if(argc < 4){
		cerr << "Usage: " << argv[0] << " <bgl file> <fam file> <0/2/3 for unrelated/pairs/trios>" << endl;
		return 0;
	}
	ifstream file_bgl(argv[1]);
	ifstream file_ped(argv[2]);

	int type = atoi( argv[3] );
	if(!file_bgl || !file_ped) { cerr << "file could not be opened" << endl; return 0; }

	stringstream ss;
	map< string , Individual > pedigree;
	map< string , Individual >::iterator pedigree_i;
	Individual cur_id;
	while ( getline( file_ped , line ) )
	{
		ss.clear(); ss.str( line );
		ss >> cur_id.id[0] >> cur_id.id[1] >> cur_id.pid[0] >> cur_id.pid[1] >> cur_id.sex >> cur_id.aff;
		pedigree.insert( make_pair( cur_id.id[1] , cur_id ) );
	}
	file_ped.close();
	cerr << "Pedigree:\t" << pedigree.size() << endl;

	// get number of individuals
	getline(file_bgl,line);
	ss.clear(); ss.str( line );
	ss >> discard >> discard;
	string id[2];
	string call[2];
	list< string > fam;
	while ( !ss.eof() )
	{
		ss >> discard >> id[0];
		fam.push_back( id[0] );

		if ( type == 2 )
		{
			ss >> id[1];
			fam.push_back( id[1] );
		} else if ( type == 3 )
		{
			ss >> discard >> id[1];
			fam.push_back( id[1] );
			// find the children
			for ( pedigree_i = pedigree.begin() ; pedigree_i != pedigree.end() ; pedigree_i++ )
			{
				if ( pedigree_i->second.pid[0] == id[0] &&  pedigree_i->second.pid[1] == id[1] ) break;
				else if ( pedigree_i->second.pid[0] == id[1] &&  pedigree_i->second.pid[1] == id[0] ) break;
			}
			if ( pedigree_i == pedigree.end() ) { cerr << "Could not find child for " << id[0] << " and " << id[1] << endl; return 0; }
			else fam.push_back( pedigree_i->second.id[1] );
		}
		
	}
	cerr << "Individuals:\t" << fam.size() << endl;
	string * seq = new string[ fam.size() ];
		
	// read all markers
	while(getline(file_bgl,line))
	{
		ss.clear(); ss.str( line );
		ss >> discard >> discard;
		if(discard == "") continue;

		// read haplotype
		for(int i=0;i< fam.size() ;i++)
		{
			ss >> call[0] >> call[1];
			seq[i] += " " + call[0] + " " + call[1];
			if ( type == 2 )
			{
				ss >> call[1];
				seq[i + 1] += " " + call[0] + " " + call[1];
				i++;
			} else if ( type == 3 )
			{
				seq[i + 2] += " " + call[0];
				ss >> call[0] >> call[1];
				seq[i + 2] += " " + call[0];
				seq[i + 1] += " " + call[0] + " " + call[1];
				i += 2;
			}
		}
	}
	// print all markers
	file_bgl.close();


	int id_ctr = 0;
	for ( list< string >::iterator i = fam.begin() ; i != fam.end() ; i++,id_ctr++ )
	{
		pedigree_i = pedigree.find( *i );
		if ( pedigree_i == pedigree.end() )
		{
			cerr << *i << " not found in fam file" << endl;
		} else
		{
			cout << pedigree_i->second.id[0] << ' ' << pedigree_i->second.id[1] << ' ' << pedigree_i->second.pid[0] << ' ' << pedigree_i->second.pid[1] << ' ' << pedigree_i->second.sex << ' ' << pedigree_i->second.aff;
			cout << seq[id_ctr] << endl;
		}
	}
	file_ped.close();
	return 1;
}
