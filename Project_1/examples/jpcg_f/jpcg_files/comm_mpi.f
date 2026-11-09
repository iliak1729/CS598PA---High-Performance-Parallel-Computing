c-----------------------------------------------------------------------
c     Minimal MPI layer for 2D jpcg.f.  Keep all MPI calls in this file.
c-----------------------------------------------------------------------
      subroutine comm_setup

      include 'mpif.h'
      include 'TOTAL'

      integer ierr

      call mpi_init(ierr)
      call mpi_comm_rank(MPI_COMM_WORLD,nid,ierr)
      call mpi_comm_size(MPI_COMM_WORLD,npq,ierr)

      nio = nid ! Initialize io discriminator to nid

      mycomm = mpi_comm_world

      wdsize = 8
      eps = 1.e-12
      if (1.0+eps.eq.1.0) wdsize=4

      rpq   = npq
      sqrtp = sqrt(rpq)
      np    = sqrtp
      nq    = npq/np
      if (np*nq.ne.npq) then
         npt = np
         do i=1,npt
            np = max(1,np-1)
            nq = npq/np
            if (np*nq.eq.npq) goto 100
         enddo
      endif
  100 continue
      if (nio.eq.0) write(6,1) np,nq,npq
    1 format(//,'Processor decomposition: ',3i8)

      pid = mod(nid,np)
      qid = nid/np
    
      return
      end
c-----------------------------------------------------------------------
      subroutine comm_finalize
      include 'mpif.h'
      include 'TOTAL'
      integer ierr
      call mpi_finalize(ierr)
      return
      end
c-----------------------------------------------------------------------
      subroutine gop(x,w,op,n)

c     Global vector reduction.  Result is returned in x on every rank.

      include 'mpif.h'
      include 'TOTAL'

      real x(n),w(n)
      character*3 op
      integer ierr

      if (op.eq.'+  ') then
         call mpi_allreduce(x,w,n,MPI_DOUBLE_PRECISION,mpi_sum,
     $                      MPI_COMM_WORLD,ierr)
      elseif (op.eq.'M  ') then
         call mpi_allreduce(x,w,n,MPI_DOUBLE_PRECISION,mpi_max,
     $                      MPI_COMM_WORLD,ierr)
      elseif (op.eq.'m  ') then
         call mpi_allreduce(x,w,n,MPI_DOUBLE_PRECISION,mpi_min,
     $                      MPI_COMM_WORLD,ierr)
      elseif (op.eq.'*  ') then
         call mpi_allreduce(x,w,n,MPI_DOUBLE_PRECISION,mpi_prod,
     $                      MPI_COMM_WORLD,ierr)
      else
         call mpi_abort(MPI_COMM_WORLD,2,ierr)
      endif
      call copy(x,w,n)
      return
      end
c-----------------------------------------------------------------------
      real*8 function dclock()
      include 'mpif.h'

      dclock=mpi_wtime()

      return
      end
c-----------------------------------------------------------------------
      function isend(msgtag,x,len,jnid,jpid)
c
c     Note: len in bytes
c
      integer x(1)

      include 'mpif.h'
      include 'TOTAL'

      call mpi_isend (x,len,mpi_byte,jnid,msgtag,mycomm,imsg,ierr)
      isend = imsg

c     write(6,*) nid,' isend:',imsg,msgtag,len,jnid,(x(k),k=1,len/4)

      return
      end
c-----------------------------------------------------------------------
      function irecv(msgtag,x,len)

      include 'mpif.h'
      include 'TOTAL'

c     Note: len in bytes

      integer x(1)


      call mpi_irecv (x,len,mpi_byte,mpi_any_source,msgtag
     $       ,mycomm,imsg,ierr)
      irecv = imsg
c     write(6,*) nid,' irecv:',imsg,msgtag,len


      return
      end
c-----------------------------------------------------------------------
      subroutine msgwait(imsg)

      include 'mpif.h'
      include 'TOTAL'

      integer status(mpi_status_size)

c     write(6,*) nid,' msgwait:',imsg

      call mpi_wait (imsg,status,ierr)

      return
      end
c-----------------------------------------------------------------------
      subroutine msgsync()

      include 'mpif.h'
      include 'TOTAL'

      call mpi_barrier(mycomm,ierr)

      return
      end
c-----------------------------------------------------------------------
      integer function nid_pq(p,q,np)

      integer p,q,np

      nid_pq = p + q*np

      return
      end
c-----------------------------------------------------------------------
