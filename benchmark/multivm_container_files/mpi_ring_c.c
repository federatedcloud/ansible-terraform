//#mpi_ring
//#ring_c.c

/*
 * Copyright (c) 2004-2006 The Trustees of Indiana University and Indiana
 *                         University Research and Technology
 *                         Corporation.  All rights reserved.
 * Copyright (c) 2006      Cisco Systems, Inc.  All rights reserved.
 *
 * Simple ring test program in C.
 */

#include <stdio.h>
#include "mpi.h"

int main(int argc, char *argv[])
{
    int rank, size, next, prev, message, tag = 201;

    /* Start up MPI */

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* Calculate the rank of the next process in the ring.  Use the
       modulus operator so that the last process "wraps around" to
       rank zero. */

    next = (rank + 1) % size;
    prev = (rank + size - 1) % size;

    /* If we are the "master" process (i.e., MPI_COMM_WORLD rank 0),
       put the number of times to go around the ring in the
       message. */

    if (0 == rank) {
        message = 10;

        printf("Process 0 sending %d to %d, tag %d (%d processes in ring)\n",
               message, next, tag, size);
        MPI_Send(&message, 1, MPI_INT, next, tag, MPI_COMM_WORLD);
        printf("Process 0 sent to %d\n", next);
    }

    /* Pass the message around the ring.  The exit mechanism works as
       follows: the message (a positive integer) is passed around the
       ring.  Each time it passes rank 0, it is decremented.  When
       each processes receives a message containing a 0 value, it
       passes the message on to the next process and then quits.  By
       passing the 0 message first, every process gets the 0 message
       and can quit normally. */

    while (1) {
        MPI_Recv(&message, 1, MPI_INT, prev, tag, MPI_COMM_WORLD,
                 MPI_STATUS_IGNORE);

        if (0 == rank) {
            --message;
            printf("Process 0 decremented value: %d\n", message);
        }

        MPI_Send(&message, 1, MPI_INT, next, tag, MPI_COMM_WORLD);
        if (0 == message) {
            printf("Process %d exiting\n", rank);
            break;
        }
    }

    /* The last process does one extra send to process 0, which needs
       to be received before the program can exit */

    if (0 == rank) {
        MPI_Recv(&message, 1, MPI_INT, prev, tag, MPI_COMM_WORLD,
                 MPI_STATUS_IGNORE);
    }

    /* All done */

    MPI_Finalize();
    return 0;
}


/*
# https://github.com/open-mpi/ompi/blob/master/LICENSE
#
#Most files in this release are marked with the copyrights of the
#organizations who have edited them.  The copyrights below are in no
#particular order and generally reflect members of the Open MPI core
#team who have contributed code to this release.  The copyrights for
#code used under license from other parties are included in the
#corresponding files.
#
#Copyright (c) 2004-2010 The Trustees of Indiana University and Indiana
#                        University Research and Technology
#                        Corporation.  All rights reserved.
#Copyright (c) 2004-2017 The University of Tennessee and The University
#                        of Tennessee Research Foundation.  All rights
#                        reserved.
#Copyright (c) 2004-2010 High Performance Computing Center Stuttgart,
#                        University of Stuttgart.  All rights reserved.
#Copyright (c) 2004-2008 The Regents of the University of California.
#                        All rights reserved.
#Copyright (c) 2006-2017 Los Alamos National Security, LLC.  All rights
#                        reserved.
#Copyright (c) 2006-2017 Cisco Systems, Inc.  All rights reserved.
#Copyright (c) 2006-2010 Voltaire, Inc. All rights reserved.
#Copyright (c) 2006-2017 Sandia National Laboratories. All rights reserved.
#Copyright (c) 2006-2010 Sun Microsystems, Inc.  All rights reserved.
#                        Use is subject to license terms.
#Copyright (c) 2006-2017 The University of Houston. All rights reserved.
#Copyright (c) 2006-2009 Myricom, Inc.  All rights reserved.
#Copyright (c) 2007-2017 UT-Battelle, LLC. All rights reserved.
#Copyright (c) 2007-2017 IBM Corporation.  All rights reserved.
#Copyright (c) 1998-2005 Forschungszentrum Juelich, Juelich Supercomputing
#                        Centre, Federal Republic of Germany
#Copyright (c) 2005-2008 ZIH, TU Dresden, Federal Republic of Germany
#Copyright (c) 2007      Evergrid, Inc. All rights reserved.
#Copyright (c) 2008      Chelsio, Inc.  All rights reserved.
#Copyright (c) 2008-2009 Institut National de Recherche en
#                        Informatique.  All rights reserved.
#Copyright (c) 2007      Lawrence Livermore National Security, LLC.
#                        All rights reserved.
#Copyright (c) 2007-2017 Mellanox Technologies.  All rights reserved.
#Copyright (c) 2006-2010 QLogic Corporation.  All rights reserved.
#Copyright (c) 2008-2017 Oak Ridge National Labs.  All rights reserved.
#Copyright (c) 2006-2012 Oracle and/or its affiliates.  All rights reserved.
#Copyright (c) 2009-2015 Bull SAS.  All rights reserved.
#Copyright (c) 2010      ARM ltd.  All rights reserved.
#Copyright (c) 2016      ARM, Inc.  All rights reserved.
#Copyright (c) 2010-2011 Alex Brick <bricka@ccs.neu.edu>.  All rights reserved.
#Copyright (c) 2012      The University of Wisconsin-La Crosse. All rights
#                        reserved.
#Copyright (c) 2013-2016 Intel, Inc. All rights reserved.
#Copyright (c) 2011-2017 NVIDIA Corporation.  All rights reserved.
#Copyright (c) 2016      Broadcom Limited.  All rights reserved.
#Copyright (c) 2011-2017 Fujitsu Limited.  All rights reserved.
#Copyright (c) 2014-2015 Hewlett-Packard Development Company, LP.  All
#                        rights reserved.
#Copyright (c) 2013-2017 Research Organization for Information Science (RIST).
#                        All rights reserved.
#Copyright (c) 2017-2018 Amazon.com, Inc. or its affiliates.  All Rights
#                        reserved.
#Copyright (c) 2018      DataDirect Networks. All rights reserved.
#Copyright (c) 2018-2019 Triad National Security, LLC. All rights reserved.
#
#$COPYRIGHT$
#
#Additional copyrights may follow
#
#$HEADER$
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are
#met:
#
#- Redistributions of source code must retain the above copyright
#  notice, this list of conditions and the following disclaimer.
#
#- Redistributions in binary form must reproduce the above copyright
#  notice, this list of conditions and the following disclaimer listed
#  in this license in the documentation and/or other materials
#  provided with the distribution.
#
#- Neither the name of the copyright holders nor the names of its
#  contributors may be used to endorse or promote products derived from
#  this software without specific prior written permission.
#
#The copyright holders provide no reassurances that the source code
#provided does not infringe any patent, copyright, or any other
#intellectual property rights of third parties.  The copyright holders
#disclaim any liability to any recipient for claims brought against
#recipient by any third party for infringement of that parties
#intellectual property rights.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
*/
