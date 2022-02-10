import React, { Fragment, useEffect, useState, useRef  } from 'react';
import { 
    useDataProvider,
    Button,
    Loading,
} from 'react-admin';

import ReactJson from 'react-json-view'



import CheckOutlinedIcon from '@material-ui/icons/CheckOutlined';
import CloseIcon from '@material-ui/icons/Close';
import CircularProgress from '@material-ui/core/CircularProgress'

import { Typography } from '@material-ui/core';
import { makeStyles  } from '@material-ui/core/styles';
import { red, green, yellow } from '@material-ui/core/colors';

import Grid from '@material-ui/core/Grid';
import Paper from '@material-ui/core/Paper';

import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import DialogTitle from '@material-ui/core/DialogTitle';


  
const useStylesJobs = makeStyles((theme) => ({
    root: {
        flexGrow: 1,
        minWidth: 300,
        minHeight: 300,
    },

    dialogPaper: { minWidth: "768px" },

    wrapper: {
      margin: theme.spacing(1),
    },

    jobLine: {
        top: "45%",
        position: "relative",
        transform: "translateY(-50%)",
    },
    
    buttonSuccess: {
        color: green[500],
        '&:hover': {
            color: green[700],
        },

      width: "35px",
      height: "35px"
    },
    buttonLoading: {
        color: yellow[500],
        '&:hover': {
            color: yellow[700],
        },
        width: "35px",
        height: "35px"
    },
    buttonFailed: {
        color: red[500],
        '&:hover': {
            color: red[700],
        },
        width: "35px",
        height: "35px"
    },

  }));





const JobDetailDialog = (props) => {
    const { onClose, open, job } = props;
    const classes = useStylesJobs();
    const handleClose = () => {
        onClose();
    };


    if (!job) { 
        return ""; 
    }

    if (open) {
        return (
            <Dialog
            open={open}
            onClose={handleClose}
            aria-labelledby="alert-dialog-task-title"
            aria-describedby="alert-dialog-task-description"
            classes={{ paper: classes.dialogPaper}}
            >
                <DialogTitle id="alert-dialog-task-title">Job Detail</DialogTitle>
                <DialogContent>
                    <ReactJson src={JSON.parse(job.content)} />
                </DialogContent>
                <DialogActions>
                    <Button label="Ok" variant="contained" color="primary" onClick={handleClose}/>
                </DialogActions>
            </Dialog>
        );
    } else {
        return '';
    }

}




  const JobsFields = ({ data }) => {
    const classes = useStylesJobs();

    const [open, setOpen] = useState(false);
    const [job, setJob] = useState(false);
    
    const handleClickOpen = (job) => {
        setOpen(true);
        setJob(job);
    };

    
    const handleClose = () => {
        setOpen(false);
    };
  
    return (
        <div>
            
            {data.map(item => (
                <Fragment key={item.id}>
                    <div key={item.id} onClick={() => handleClickOpen(item)} style={{cursor:'pointer'}}>
                        <Grid container spacing={0}  direction="row">
                            <Grid item xs={1} className={classes.gridIcon}>
                                {item.status === "success" && <CheckOutlinedIcon className={classes.buttonSuccess} /> }
                                {item.status === "failed" && <CloseIcon className={classes.buttonFailed}/> }
                                {(item.status !== "failed" && item.status !== "success") && <CircularProgress size={30} className={classes.buttonLoading} />} 
                            </Grid>
                            <Grid item xs={11} className={classes.gridText}>
                                <Typography variant="body2" className={classes.jobLine}>&nbsp;&nbsp;&nbsp;{item.created_at} </Typography>
                            </Grid>
                            
                        </Grid>
                    </div>
                </Fragment>
                
            ))}
            <JobDetailDialog job={job} open={open} onClose={handleClose}/>
        </div>
    )
};






export const CustomJobListAside = ({ record, ...props }) => {

    const classes = useStylesJobs();
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState();
    const dataProvider = useDataProvider();
    const [data, setData] = useState();
    
    var timerToRefresh = useRef(null);
    var global_refreshing = false;
    
    useEffect(() => {
        if (typeof record !== 'undefined') {
            setTimeout(() => { //SLEEPING FOR 1 SECOND BECAUSE UI/API ARE TOO FAST AND GITLAB HASN'T UPDATED ITS JOBS LIST YET.... :(
                dataProvider.getList('wan_sites/'+record.id+"/jobs").then(({ data }) => {
                    if (data.some(item => item.status !== 'failed' && item.status !== 'success')) {
                        global_refreshing = true;
                        timerToRefresh = setInterval(() => refreshList(), 5000);
                
                    } else {
                        global_refreshing = false;
                        clearInterval(timerToRefresh);     

                    }
                    setData(data);
                    setLoading(false);
                })
                .catch(error => {
                    setError(error);
                    setLoading(false);
                })
            }, 1000); //SLEEPING FOR 1 SECOND BECAUSE UI/API ARE TOO FAST AND GITLAB HASN'T UPDATED ITS JOBS LIST YET.... :(
            
        }
    }, [record]);


    function refreshList(e) {
        dataProvider.getList('wan_sites/'+record.id+"/jobs").then(({ data }) => {
            if (data.some(item => item.status !== 'failed' && item.status !== 'success')) {
                if (global_refreshing === false) {
                    global_refreshing = true;
                    timerToRefresh = setInterval(() => refreshList(), 5000);
                }
            } else {
                global_refreshing = false;
                clearInterval(timerToRefresh);
            }
            setData(data);
            setLoading(false);
        })
        .catch(error => {
            setError(error);
            setLoading(false);
        })
    }
    
    if (!record) return <Loading />;
    if (loading) return <Loading />;
    if (error) return 'erro ao pegar atualizações recentes';
    if (!data) return null;

    return (

        <div className={classes.root} style={{ minWidth: '300px', maxWidth: '300px'}}>
            <Paper elevation={1}>
            <Typography variant="h6" style={{ textAlign: 'center'}}>Last 5 Jobs</Typography>
            <div className={classes.wrapper}>
                <JobsFields data={data} />
            </div>
            </Paper>
        </div>


    )
};


