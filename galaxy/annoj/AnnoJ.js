    //The Anno-J configuration object  
    AnnoJ.config = {  
      
        //List of configurations for all tracks in the Anno-J instance  
        tracks : [  
      
            //Example config for a ModelsTrack  
            {  
                id   : 'models',  
                name : 'Gene Models',  
                type : 'ModelsTrack',  
                path : 'Annotation models',  
      
                //Pointing to a local service  
                data : 'fetchers/models.php',  
                height : 80,  
                showControls : true  
            },  
              
            //Example config for a MethTrack  
            {  
                id   : 'meth',  
                name : '5-methyl cytosine sites',  
                type : 'MethTrack',  
                path : 'DNA methylation',  
                  
                //Pointing to a remote service, the server must be configured as a reverse proxy  
                data : 'proxy/http://some.remote.site/methylation.php',  
                iconCls : 'salk_meth',  
                height : 40  
            },  
              
            //Example config for a ReadsTrack  
            {  
                id   : 'reads',  
                name : 'Deep sequencing',  
                type : 'ReadsTrack',  
                path : 'Reads',  
                data : 'fetchers/bisulfite.php',  
                iconCls : 'salk_meth',  
                height : 70  
            },    
              
            //Example config for a MicroarrayTrack  
            {  
                id   : 'wgta',  
                name : 'Whole genome tiling array',  
                type : 'MicroarrayTrack',  
                path : 'Messenger RNA',  
                data : 'fetchers/microarray.php',  
                iconCls : 'salk_mrna',  
                height : 60  
            },  
              
            //Example config for a SmallReadsTrack  
            {  
                id   : 'smrna_col0',  
                name : 'smRNA Col-0',  
                type : 'SmallReadsTrack',  
                path : 'Small RNA',  
                data : 'fetchers/smrna.php',  
                iconCls : 'salk_smrna',  
                height : 40  
            }  
        ],  
          
        //A list of tracks that will be active by default (use the ID of the track)  
        active : [  
            'models','meth','reads'  
        ],  
          
        //Address of service that provides information about this genome  
        genome    : 'fetchers/arabidopsis_thaliana.php',  
          
        //Address of service that stores / loads user bookmarks  
        bookmarks : 'fetchers/arabidopsis_thaliana.php',  
      
        //A list of stylesheets that a user can select between (optional)  
        stylesheets : [  
            {  
                id   : 'css1',  
                name : 'Plugins CSS',  
                href : 'css/plugins.css',  
                active : true  
            },{  
                id   : 'css2',  
                name : 'SALK CSS',  
                href : 'css/salk.css',  
                active : true  
            }         
        ],  
          
        //The default 'view'. In this example, chr1, position 1, zoom ratio 20:1.  
        location : {  
            assembly : '1',  
            position : 1,  
            bases    : 20,  
            pixels   : 1  
        },  
          
        //Site administrator contact details (optional)  
        admin : {  
            name  : 'Julian Tonti-Filippini',  
            email : 'tontij01@student.uwa.edu.au',  
            notes : 'Perth, Western Australia (UTC +8)'  
        }  
    };  
